# ECB XML Parsing in MS SQL Server

## Overview

This module processes ECB XML exchange rate data in Microsoft SQL Server.

The XML source is loaded into:

- `@XML_SRC XML`

The output is normalized into two tables:

- `dbo.tblCurrency`
- `dbo.tblCurrencyRate`

## Main implementation features

- namespace-aware XML parsing
- normalized schema
- primary key and foreign key constraints
- unique constraint on `(CurrencyCode, RateDate)`
- base currency support (`EUR`)
- analytical check query

## Notes

The script supports loading XML from a local file through `OPENROWSET`.
In SQL Server environments, access to `OPENROWSET` may require additional configuration and permissions.

XML parsing is computationally more expensive than loading already normalized data, so this part is presented as a batch-oriented integration workflow rather than a high-frequency runtime query pattern.