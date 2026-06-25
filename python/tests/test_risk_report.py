from decimal import Decimal

import pytest

from risk_report import (
    CURRENCY,
    ENTITY_CODE,
    MGMT_FEE_BPS,
    REGULATOR,
    build_report,
    is_reportable,
    management_fee,
)


def test_management_fee_one_million():
    assert management_fee(Decimal("1000000")) == Decimal("6000")


def test_management_fee_zero():
    assert management_fee(Decimal("0")) == Decimal("0.00")


def test_is_reportable_at_threshold():
    assert is_reportable(Decimal("1000000")) is True


def test_is_reportable_below_threshold():
    assert is_reportable(Decimal("999999.99")) is False


def test_build_report_hong_kong_fields():
    report = build_report("PF-001", Decimal("1000000"))
    assert report["entity_code"] == "HK"
    assert report["currency"] == "HKD"
    assert report["regulator"] == "SFC"
    assert report["management_fee"] == Decimal("6000")
    assert report["management_fee_bps"] == MGMT_FEE_BPS
    assert report["reportable"] is True
    assert "SFC Code of Conduct" in report["disclosure"]
