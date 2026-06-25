# COBOL — PORTVAL

`PORTVAL.cbl` is a nightly batch program that reads portfolio records, computes management fees, checks large-position reportability, and emits valuation lines for the Hong Kong booking centre.

## Hong Kong assumptions (refactoring targets)

| Constant | Current (HK) | SG target | CH target |
|----------|-------------|-----------|-----------|
| Currency | HKD | SGD | CHF |
| Locale | en_HK / zh_HK | en_SG | de_CH / fr_CH |
| Regulator | SFC | MAS | FINMA |
| Booking centre | Hong Kong | Singapore | Zurich |
| Management fee | 60 bps | Entity fee schedule | Entity fee schedule |
| Large position threshold | 1,000,000 HKD | SGD equivalent | CHF equivalent |
| Disclosure text | SFC Code of Conduct | MAS Notice FAA | FINMA disclosure rules |

## Refactoring approach

Replace `WORKING-STORAGE` literals with a configuration record loaded at batch start (entity code, currency, fee bps, threshold, disclosure template). The paragraph structure can remain; only the data source changes.
