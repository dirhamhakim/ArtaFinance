"""Read an IDX XLSX without modifying it; build a local stock catalog (stdlib only)."""

import argparse
from collections import Counter
from datetime import date
import hashlib
import json
from pathlib import Path
import posixpath
import re
import xml.etree.ElementTree as ET
import zipfile


NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
HEADERS = ["No", "Kode", "Nama Perusahaan", "Tanggal Pencatatan", "Saham", "Papan Pencatatan"]
REQUIRED_HEADERS = HEADERS[1:]
MONTHS = {
    "jan": 1, "feb": 2, "mar": 3, "apr": 4, "mei": 5, "may": 5,
    "jun": 6, "jul": 7, "agu": 8, "ags": 8, "agt": 8, "aug": 8, "sep": 9,
    "okt": 10, "oct": 10, "nov": 11, "des": 12, "dec": 12,
}


def read_sheet(source, sheet_name):
    with zipfile.ZipFile(source) as archive:
        workbook = ET.fromstring(archive.read("xl/workbook.xml"))
        sheets = workbook.findall("m:sheets/m:sheet", NS)
        sheet = next((s for s in sheets if s.get("name") == sheet_name), None)
        if sheet is None:
            raise ValueError(f"Sheet {sheet_name!r} not found")
        relationships = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
        target = next(r.get("Target") for r in relationships
                      if r.get("Id") == sheet.get(f"{{{REL_NS}}}id"))
        sheet_path = target.lstrip("/") if target.startswith("/") else posixpath.normpath("xl/" + target)
        strings = []
        if "xl/sharedStrings.xml" in archive.namelist():
            strings = ["".join(t.text or "" for t in item.findall(".//m:t", NS))
                       for item in ET.fromstring(archive.read("xl/sharedStrings.xml"))]
        root = ET.fromstring(archive.read(sheet_path))
        rows = []
        for row in root.findall("m:sheetData/m:row", NS):
            values = {}
            for cell in row.findall("m:c", NS):
                address = cell.get("r")
                kind = cell.get("t")
                if cell.find("m:f", NS) is not None or kind == "e":
                    raise ValueError(f"Formula or error at {sheet_name}!{address}; inspect source first")
                if kind == "s":
                    value = strings[int(cell.findtext("m:v", "", NS))]
                elif kind == "inlineStr":
                    value = "".join(t.text or "" for t in cell.findall("m:is//m:t", NS))
                else:
                    if kind == "b":
                        raise ValueError(f"Boolean at {address}; identifiers must remain text")
                    value = cell.findtext("m:v", "", NS)
                values[re.sub(r"\d", "", address)] = value
            if any(value.strip() for value in values.values()):
                rows.append((int(row.get("r")), values))
        return rows, [s.get("name") for s in sheets]


def parse_listing_date(value):
    day, month, year = value.split()
    return date(int(year), MONTHS[month.casefold()], int(day)).isoformat()


def parse_shares_count(value):
    value = value.strip()
    if not re.fullmatch(r"(?:[0-9]+|[0-9]{1,3}(?:\.[0-9]{3})+)", value):
        raise ValueError(f"Unexpected shares format: {value!r}")
    count = int(value.replace(".", ""))
    if count > 2**63 - 1:
        raise ValueError("Shares count exceeds SQLite signed 64-bit integer capacity")
    return str(count)


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("--downloaded-on", required=True, type=date.fromisoformat)
    parser.add_argument("--sheet", default="Sheet1")
    parser.add_argument("--output", type=Path, default=Path("assets/data/idx_stocks.json"))
    parser.add_argument("--report", type=Path, default=Path("docs/data/idx-catalog-validation.json"))
    args = parser.parse_args()
    if args.source.resolve() in {args.output.resolve(), args.report.resolve()}:
        raise ValueError("Output must differ from the source workbook")
    source_hash = hashlib.sha256(args.source.read_bytes()).hexdigest()
    rows, sheet_names = read_sheet(args.source, args.sheet)
    if not rows:
        raise ValueError("Empty IDX workbook")
    source_headers = {column: value.strip() for column, value in rows[0][1].items() if value.strip()}
    if (len(set(source_headers.values())) != len(source_headers)
            or not set(REQUIRED_HEADERS).issubset(source_headers.values())
            or set(source_headers.values()) - set(HEADERS)):
        raise ValueError("Unexpected IDX headers; review the workbook before conversion")
    stocks, codes, warnings = [], set(), []
    for row_number, values in rows[1:]:
        if any(column not in source_headers and value.strip() for column, value in values.items()):
            raise ValueError(f"Unexpected populated column on row {row_number}")
        fields = {header: values.get(column, "") for column, header in source_headers.items()}
        code = fields.get("Kode", "").strip().upper()
        name = fields.get("Nama Perusahaan", "").strip()
        if not re.fullmatch(r"[A-Z]{4}", code) or not name:
            raise ValueError(f"Invalid or blank code/name on row {row_number}")
        if code in codes:
            raise ValueError(f"Duplicate code {code} on row {row_number}")
        try:
            shares_count = parse_shares_count(fields.get("Saham", ""))
        except ValueError as error:
            raise ValueError(f"Invalid shares count on row {row_number}: {error}") from error
        listing_date = parse_listing_date(fields.get("Tanggal Pencatatan", ""))
        board = fields.get("Papan Pencatatan", "").strip()
        if not board:
            raise ValueError(f"Missing listing board on row {row_number}")
        if listing_date > args.downloaded_on.isoformat():
            warnings.append({"code": code, "source_row": row_number, "issue": "listing_date_after_download"})
        codes.add(code)
        stocks.append({
            "code": code, "name": name, "exchange": "IDX", "instrument_type": "stock",
            "yahoo_symbol": code + ".JK", "listing_date": listing_date,
            "shares_count": shares_count, "listing_board": board, "source_row": row_number,
        })
    if not stocks:
        raise ValueError("No stocks found")
    stocks.sort(key=lambda item: item["code"])
    longest_name = max(len(s["name"]) for s in stocks)
    if longest_name == 30:
        warnings.append({
            "issue": "possible_source_name_truncation",
            "name_length_limit_observed": 30,
            "records_at_limit": sum(len(s["name"]) == 30 for s in stocks),
            "note": "Some source names appear cut off. Not every name at the limit is incomplete. Names are preserved, not inferred.",
        })
    metadata = {
        "schema_version": 1,
        "catalog_version": f"idx-{args.downloaded_on.isoformat()}-{source_hash[:12]}-r2",
        "source": {
            "provider": "IDX", "attribution": "User-provided download from IDX",
            "file_name": args.source.name, "sha256": source_hash,
            "downloaded_on": args.downloaded_on.isoformat(), "download_date_basis": "user_provided",
            "source_as_of": None, "sheet": args.sheet,
            "range": f"A{rows[0][0]}:{max(source_headers, key=lambda c: (len(c), c))}{rows[-1][0]}",
        },
        "record_count": len(stocks),
        "yahoo_mapping_verified": False,
        "logo_url_template": "https://assets.stockbit.com/logos/companies/{code}.png",
    }
    report = {
        "catalog_version": metadata["catalog_version"], "source_sha256": source_hash,
        "sheets": sheet_names, "source_headers": list(source_headers.values()), "data_rows": len(rows) - 1,
        "catalog_records": len(stocks), "unique_codes": len(codes), "rejected_rows": 0,
        "shares_count_records": sum("shares_count" in s for s in stocks),
        "shares_count_min": str(min(int(s["shares_count"]) for s in stocks)),
        "shares_count_max": str(max(int(s["shares_count"]) for s in stocks)),
        "listing_date_min": min(s["listing_date"] for s in stocks),
        "listing_date_max": max(s["listing_date"] for s in stocks),
        "listing_board_counts": dict(sorted(Counter(s["listing_board"] for s in stocks).items())),
        "name_length_counts": dict(sorted(Counter(len(s["name"]) for s in stocks).items())),
        "warnings": warnings,
        "checks": {
            "expected_headers": True, "unique_nonblank_codes_and_names": True,
            "four_letter_stock_codes": True, "source_number_column_ignored": True,
            "listing_dates_parsed": True, "shares_format_checked": True,
            "shares_count_preserved_exactly": True,
            "no_formula_or_error_cells": True, "names_preserved_after_edge_trimming": True,
        },
        "external_checks": {"idx_completeness": "not_verified", "yahoo_prices": "not_verified", "stockbit_logos": "not_verified"},
    }
    if hashlib.sha256(args.source.read_bytes()).hexdigest() != source_hash:
        raise ValueError("Source changed during inspection; rerun conversion")
    write_json(args.output, {**metadata, "stocks": stocks})
    write_json(args.report, report)
    saved = json.loads(args.output.read_text(encoding="utf-8"))
    if saved["stocks"] != stocks or saved["record_count"] != len(stocks):
        raise ValueError("JSON round-trip validation failed")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
