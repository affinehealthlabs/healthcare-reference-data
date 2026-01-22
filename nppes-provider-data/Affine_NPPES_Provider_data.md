# Affine NPPES Healthcare Provider Data
## Snowflake Marketplace Data Listing Documentation

---

## Overview

The **NPPES Healthcare Provider Data** listing provides a comprehensive, analytics-ready dimensional model of the National Plan and Provider Enumeration System (NPPES) maintained by the Centers for Medicare & Medicaid Services (CMS). This dataset contains information on all healthcare providers who have been assigned a National Provider Identifier (NPI).

### Key Benefits

- **Analytics-Ready**: Pre-built dimensional model optimized for BI tools and analytics
- **Enriched Data**: Taxonomy codes joined with NUCC descriptions for human-readable specialties
- **Derived Fields**: Pre-calculated fields like IS_ACTIVE, PROVIDER_FULL_NAME, and parsed addresses
- **Monthly Updates**: Refreshed monthly aligned with CMS NPPES release schedule
- **Complete Coverage**: All 8M+ healthcare providers in the United States

---

## Data Source

| Attribute | Value |
|-----------|-------|
| **Source** | CMS National Plan and Provider Enumeration System (NPPES) |
| **Source URL** | https://download.cms.gov/nppes/NPI_Files.html |
| **Taxonomy Reference** | NUCC Healthcare Provider Taxonomy Code Set (https://nucc.org/) |
| **Update Frequency** | Monthly (within 5 business days of CMS release) |
| **Historical Data** | Current snapshot (no historical versioning) |
| **Geographic Coverage** | United States and U.S. Territories |

---

## Schema Overview

```
├── REF_DW (Data Warehouse Schema)
│   ├── DIM_PROVIDER              -- Core provider dimension
│   ├── DIM_PROVIDER_ADDRESS      -- Mailing and practice addresses
│   ├── DIM_PROVIDER_TAXONOMY     -- Provider specialty codes (up to 15 per provider)
│   ├── DIM_PROVIDER_IDENTIFIER   -- Other IDs: Medicare, Medicaid (up to 50 per provider)
│   ├── DIM_PROVIDER_ENDPOINT     -- Digital endpoints: FHIR, Direct addresses
│   ├── DIM_AUTHORIZED_OFFICIAL   -- Organization authorized contacts
│   └── REF_TAXONOMY_CODE         -- NUCC taxonomy code reference
│
└── Views (Pre-built Analytics)
    ├── VW_PROVIDER_SUMMARY       -- Complete provider profile
    ├── VW_ACTIVE_PROVIDERS       -- Active providers only
    ├── VW_PROVIDERS_BY_STATE     -- State aggregations
    ├── VW_PROVIDERS_BY_SPECIALTY -- Specialty aggregations
    └── ... (18 total views)
```

---

## Table Definitions

### DIM_PROVIDER
**Description**: Core provider dimension containing NPI, demographics, and primary taxonomy.

| Column | Data Type | Description |
|--------|-----------|-------------|
| PROVIDER_SK | NUMBER | Surrogate key (auto-generated) |
| NPI | VARCHAR(10) | National Provider Identifier (unique) |
| ENTITY_TYPE_CODE | VARCHAR(1) | '1' = Individual, '2' = Organization |
| ENTITY_TYPE_DESC | VARCHAR(20) | 'Individual' or 'Organization' |
| ORGANIZATION_NAME_LBN | VARCHAR(70) | Legal business name (Type 2 only) |
| PROVIDER_LAST_NAME | VARCHAR(35) | Last name (Type 1 only) |
| PROVIDER_FIRST_NAME | VARCHAR(20) | First name (Type 1 only) |
| PROVIDER_MIDDLE_NAME | VARCHAR(20) | Middle name (Type 1 only) |
| PROVIDER_NAME_PREFIX | VARCHAR(5) | Name prefix (Dr., Mr., etc.) |
| PROVIDER_NAME_SUFFIX | VARCHAR(5) | Name suffix (Jr., III, etc.) |
| PROVIDER_CREDENTIAL | VARCHAR(20) | Credentials (MD, DO, RN, etc.) |
| PROVIDER_FULL_NAME | VARCHAR(150) | **Derived**: Concatenated full name |
| PROVIDER_SEX_CODE | VARCHAR(1) | 'M' = Male, 'F' = Female |
| PROVIDER_SEX_DESC | VARCHAR(10) | 'Male' or 'Female' |
| PRIMARY_TAXONOMY_CODE | VARCHAR(10) | Primary specialty taxonomy code |
| PRIMARY_TAXONOMY_LICENSE_NUMBER | VARCHAR(20) | License number for primary taxonomy |
| PRIMARY_TAXONOMY_LICENSE_STATE | VARCHAR(2) | State of licensure |
| IS_SOLE_PROPRIETOR | VARCHAR(1) | 'Y', 'N', or 'X' (not answered) |
| IS_SOLE_PROPRIETOR_DESC | VARCHAR(15) | 'Yes', 'No', or 'Not Answered' |
| IS_ORGANIZATION_SUBPART | VARCHAR(1) | Organization subpart indicator |
| PARENT_ORGANIZATION_LBN | VARCHAR(70) | Parent organization name |
| EIN | VARCHAR(9) | Employer Identification Number |
| ENUMERATION_DATE | DATE | Date NPI was assigned |
| LAST_UPDATE_DATE | DATE | Last update in NPPES |
| DEACTIVATION_DATE | DATE | NPI deactivation date (if applicable) |
| DEACTIVATION_REASON_CODE | VARCHAR(2) | DT=Death, DB=Disbandment, FR=Fraud, OT=Other |
| DEACTIVATION_REASON_DESC | VARCHAR(20) | Human-readable deactivation reason |
| REACTIVATION_DATE | DATE | NPI reactivation date (if applicable) |
| IS_ACTIVE | BOOLEAN | **Derived**: TRUE if currently active |
| DW_INSERT_TIMESTAMP | TIMESTAMP_NTZ | Record creation timestamp |
| DW_UPDATE_TIMESTAMP | TIMESTAMP_NTZ | Record last update timestamp |

**Row Count**: ~8.5 million providers

---

### DIM_PROVIDER_ADDRESS
**Description**: Provider mailing and practice location addresses.

| Column | Data Type | Description |
|--------|-----------|-------------|
| ADDRESS_SK | NUMBER | Surrogate key (auto-generated) |
| PROVIDER_SK | NUMBER | Foreign key to DIM_PROVIDER |
| NPI | VARCHAR(10) | National Provider Identifier |
| ADDRESS_TYPE_CODE | VARCHAR(10) | 'MAILING' or 'PRACTICE' |
| ADDRESS_TYPE_DESC | VARCHAR(50) | Address type description |
| IS_PRIMARY | BOOLEAN | Primary address indicator |
| ADDRESS_LINE_1 | VARCHAR(55) | Street address line 1 |
| ADDRESS_LINE_2 | VARCHAR(55) | Street address line 2 |
| CITY_NAME | VARCHAR(40) | City name |
| STATE_CODE | VARCHAR(40) | State code (2-letter) |
| POSTAL_CODE | VARCHAR(20) | Full postal code |
| POSTAL_CODE_5 | VARCHAR(5) | **Derived**: 5-digit ZIP |
| POSTAL_CODE_4 | VARCHAR(4) | **Derived**: ZIP+4 extension |
| COUNTRY_CODE | VARCHAR(2) | Country code (if outside US) |
| IS_US_ADDRESS | BOOLEAN | **Derived**: TRUE if US address |
| TELEPHONE_NUMBER | VARCHAR(20) | Phone number (formatted) |
| TELEPHONE_DIGITS | VARCHAR(20) | **Derived**: Digits only |
| FAX_NUMBER | VARCHAR(20) | Fax number (formatted) |
| FAX_DIGITS | VARCHAR(20) | **Derived**: Digits only |
| FULL_ADDRESS | VARCHAR(250) | **Derived**: Concatenated address |

**Row Count**: ~17 million addresses (~2 per provider)

---

### DIM_PROVIDER_TAXONOMY
**Description**: Provider taxonomy codes (specialties). Providers may have up to 15 taxonomy codes.

| Column | Data Type | Description |
|--------|-----------|-------------|
| TAXONOMY_SK | NUMBER | Surrogate key (auto-generated) |
| PROVIDER_SK | NUMBER | Foreign key to DIM_PROVIDER |
| NPI | VARCHAR(10) | National Provider Identifier |
| TAXONOMY_SEQUENCE | NUMBER | Sequence number (1-15) |
| TAXONOMY_CODE | VARCHAR(10) | NUCC taxonomy code |
| IS_PRIMARY_TAXONOMY | BOOLEAN | TRUE if primary specialty |
| LICENSE_NUMBER | VARCHAR(20) | State license number |
| LICENSE_STATE_CODE | VARCHAR(2) | State of licensure |
| TAXONOMY_GROUP | VARCHAR(10) | Taxonomy group code |

**Row Count**: ~12 million taxonomy associations

---

### DIM_PROVIDER_IDENTIFIER
**Description**: Other provider identifiers including Medicare and Medicaid IDs.

| Column | Data Type | Description |
|--------|-----------|-------------|
| IDENTIFIER_SK | NUMBER | Surrogate key (auto-generated) |
| PROVIDER_SK | NUMBER | Foreign key to DIM_PROVIDER |
| NPI | VARCHAR(10) | National Provider Identifier |
| IDENTIFIER_SEQUENCE | NUMBER | Sequence number (1-50) |
| IDENTIFIER_VALUE | VARCHAR(20) | Identifier value |
| IDENTIFIER_TYPE_CODE | VARCHAR(2) | Identifier type code |
| IDENTIFIER_TYPE_DESC | VARCHAR(50) | Identifier type description |
| IDENTIFIER_STATE | VARCHAR(2) | State where issued |
| IDENTIFIER_ISSUER | VARCHAR(80) | Issuing organization |
| IS_MASKED | BOOLEAN | **Derived**: TRUE if value is masked |

**Identifier Type Codes**:
| Code | Description |
|------|-------------|
| 01 | Other (non-Medicare) |
| 02 | Medicare UPIN |
| 04 | Medicare ID-Type Unspecified |
| 05 | Medicaid |
| 06 | Medicare OSCAR/Certification |
| 07 | Medicare NSC |
| 08 | Medicare PIN |

**Row Count**: ~15 million identifiers

---

### DIM_PROVIDER_ENDPOINT
**Description**: Provider digital endpoints including FHIR APIs and Direct addresses.

| Column | Data Type | Description |
|--------|-----------|-------------|
| ENDPOINT_SK | NUMBER | Surrogate key (auto-generated) |
| PROVIDER_SK | NUMBER | Foreign key to DIM_PROVIDER |
| NPI | VARCHAR(10) | National Provider Identifier |
| ENDPOINT_SEQUENCE | NUMBER | Sequence number |
| ENDPOINT_TYPE | VARCHAR(50) | Endpoint type code |
| ENDPOINT_TYPE_DESCRIPTION | VARCHAR(500) | Endpoint type description |
| ENDPOINT | VARCHAR(500) | Endpoint URL or address |
| ENDPOINT_DESCRIPTION | VARCHAR(500) | Endpoint description |
| IS_AFFILIATED | BOOLEAN | Affiliated endpoint indicator |
| AFFILIATION_LBN | VARCHAR(70) | Affiliated organization name |
| USE_CODE | VARCHAR(50) | Use code |
| USE_DESCRIPTION | VARCHAR(500) | Use description |
| CONTENT_TYPE | VARCHAR(50) | Content type code |
| CONTENT_DESCRIPTION | VARCHAR(500) | Content type description |
| ENDPOINT_PROTOCOL | VARCHAR(10) | **Derived**: HTTP, HTTPS, DIRECT, OTHER |
| IS_FHIR_ENDPOINT | BOOLEAN | **Derived**: TRUE if FHIR endpoint |
| IS_DIRECT_ADDRESS | BOOLEAN | **Derived**: TRUE if Direct address |

**Row Count**: ~3 million endpoints

---

### DIM_AUTHORIZED_OFFICIAL
**Description**: Authorized officials for organization (Type 2) providers.

| Column | Data Type | Description |
|--------|-----------|-------------|
| AUTHORIZED_OFFICIAL_SK | NUMBER | Surrogate key (auto-generated) |
| PROVIDER_SK | NUMBER | Foreign key to DIM_PROVIDER |
| NPI | VARCHAR(10) | National Provider Identifier |
| LAST_NAME | VARCHAR(35) | Last name |
| FIRST_NAME | VARCHAR(20) | First name |
| MIDDLE_NAME | VARCHAR(20) | Middle name |
| NAME_PREFIX | VARCHAR(5) | Name prefix |
| NAME_SUFFIX | VARCHAR(5) | Name suffix |
| CREDENTIAL | VARCHAR(20) | Credentials |
| FULL_NAME | VARCHAR(150) | **Derived**: Concatenated name |
| TITLE_OR_POSITION | VARCHAR(35) | Title or position |
| TELEPHONE_NUMBER | VARCHAR(20) | Phone number |
| TELEPHONE_DIGITS | VARCHAR(20) | **Derived**: Digits only |

**Row Count**: ~1.5 million authorized officials

---

### REF_TAXONOMY_CODE
**Description**: NUCC Healthcare Provider Taxonomy Code reference table.

| Column | Data Type | Description |
|--------|-----------|-------------|
| TAXONOMY_CODE | VARCHAR(10) | Taxonomy code (primary key) |
| TAXONOMY_TYPE | VARCHAR(100) | Provider type grouping |
| TAXONOMY_CLASSIFICATION | VARCHAR(100) | Specialty classification |
| TAXONOMY_SPECIALIZATION | VARCHAR(100) | Sub-specialization |
| TAXONOMY_DEFINITION | VARCHAR(4000) | Code definition |
| TAXONOMY_NOTES | VARCHAR(4000) | Additional notes |
| EFFECTIVE_DATE | DATE | Code effective date |
| DEACTIVATION_DATE | DATE | Code deactivation date |
| IS_ACTIVE | BOOLEAN | Active code indicator |

**Row Count**: ~900 taxonomy codes

---

## Pre-Built Views

### Provider Profile Views

| View | Description | Key Use Case |
|------|-------------|--------------|
| `VW_PROVIDER_SUMMARY` | Complete provider profile with taxonomy descriptions and addresses | Provider lookup, CRM integration |
| `VW_ACTIVE_PROVIDERS` | Currently active providers only | Provider directories |
| `VW_INDIVIDUAL_PROVIDERS` | Type 1 individual providers with credentials | Physician directories |
| `VW_ORGANIZATION_PROVIDERS` | Type 2 organizations with authorized officials | Facility directories |
| `VW_PROVIDER_SEARCH` | Optimized for search with SEARCH_NAME column | Provider search applications |

### Geographic Analysis

| View | Description | Key Use Case |
|------|-------------|--------------|
| `VW_PROVIDERS_BY_STATE` | Provider counts by state | Market analysis |
| `VW_STATE_SPECIALTY_MATRIX` | State × specialty cross-tab | Network adequacy |

### Specialty Analysis

| View | Description | Key Use Case |
|------|-------------|--------------|
| `VW_PROVIDERS_BY_SPECIALTY` | Counts by taxonomy code | Specialty distribution |
| `VW_PROVIDER_ALL_TAXONOMIES` | All taxonomies per provider | Multi-specialty analysis |
| `VW_MULTI_SPECIALTY_PROVIDERS` | Providers with 2+ specialties | Practice pattern analysis |

### Digital Health

| View | Description | Key Use Case |
|------|-------------|--------------|
| `VW_PROVIDER_ENDPOINTS` | All digital endpoints | Interoperability analysis |
| `VW_FHIR_ENABLED_PROVIDERS` | FHIR-enabled providers | FHIR adoption tracking |

### Compliance & Identifiers

| View | Description | Key Use Case |
|------|-------------|--------------|
| `VW_PROVIDER_IDENTIFIERS` | All other IDs (masked) | Identifier crosswalk |
| `VW_MEDICARE_PROVIDERS` | Medicare ID holders | Medicare enrollment |

### Trends & Analytics

| View | Description | Key Use Case |
|------|-------------|--------------|
| `VW_DEACTIVATED_PROVIDERS` | Deactivated NPIs with reasons | Attrition analysis |
| `VW_DEACTIVATION_SUMMARY` | Deactivation trends | Workforce planning |
| `VW_NEW_PROVIDERS_BY_MONTH` | Monthly enrollment trends | Growth forecasting |
| `VW_PROVIDER_GROWTH_YOY` | Year-over-year growth | Market trends |

### Data Quality

| View | Description | Key Use Case |
|------|-------------|--------------|
| `VW_DATA_QUALITY_SUMMARY` | Completeness metrics | Data validation |
| `VW_ETL_BATCH_HISTORY` | Load history | Refresh monitoring |

---

## Sample Queries

### 1. Find Active Physicians by State and Specialty

```sql
SELECT 
    STATE_CODE,
    SPECIALTY,
    COUNT(*) AS PHYSICIAN_COUNT
FROM VW_ACTIVE_PROVIDERS
WHERE PROVIDER_TYPE = 'Allopathic & Osteopathic Physicians'
  AND STATE_CODE IN ('CA', 'TX', 'NY', 'FL')
GROUP BY STATE_CODE, SPECIALTY
ORDER BY STATE_CODE, PHYSICIAN_COUNT DESC;
```

### 2. Provider Lookup by NPI

```sql
SELECT *
FROM VW_PROVIDER_SUMMARY
WHERE NPI = '1234567890';
```

### 3. Search Providers by Name and Location

```sql
SELECT 
    NPI,
    PROVIDER_NAME,
    SPECIALTY,
    CITY_NAME,
    STATE_CODE,
    PHONE
FROM VW_PROVIDER_SEARCH
WHERE SEARCH_NAME LIKE '%SMITH%'
  AND STATE_CODE = 'CA'
  AND IS_ACTIVE = TRUE
LIMIT 100;
```

### 4. FHIR-Enabled Organizations by State

```sql
SELECT 
    PRACTICE_STATE,
    COUNT(DISTINCT NPI) AS FHIR_ENABLED_COUNT
FROM VW_FHIR_ENABLED_PROVIDERS
WHERE ENTITY_TYPE_DESC = 'Organization'
GROUP BY PRACTICE_STATE
ORDER BY FHIR_ENABLED_COUNT DESC;
```

### 5. Top Specialties with Growth Analysis

```sql
SELECT 
    SPECIALTY,
    TOTAL_PROVIDERS,
    ACTIVE_PROVIDERS,
    ROUND(ACTIVE_PROVIDERS * 100.0 / TOTAL_PROVIDERS, 1) AS ACTIVE_PCT,
    EARLIEST_ENUMERATION,
    LATEST_ENUMERATION
FROM VW_PROVIDERS_BY_SPECIALTY
WHERE TOTAL_PROVIDERS >= 1000
ORDER BY TOTAL_PROVIDERS DESC
LIMIT 20;
```

### 6. Provider Network Coverage Analysis

```sql
SELECT 
    STATE_CODE,
    SPECIALTY,
    PROVIDER_COUNT,
    ROUND(PROVIDER_COUNT * 100.0 / SUM(PROVIDER_COUNT) OVER (PARTITION BY STATE_CODE), 2) AS PCT_OF_STATE
FROM VW_STATE_SPECIALTY_MATRIX
WHERE STATE_CODE = 'TX'
ORDER BY PROVIDER_COUNT DESC;
```

### 7. Medicare Provider Lookup

```sql
SELECT 
    NPI,
    PROVIDER_NAME,
    SPECIALTY,
    MEDICARE_ID_TYPE,
    MEDICARE_ID,
    PRACTICE_STATE
FROM VW_MEDICARE_PROVIDERS
WHERE PRACTICE_STATE = 'FL'
  AND IS_ACTIVE = TRUE
  AND MEDICARE_ID_TYPE = 'Medicare OSCAR/Certification';
```

### 8. Deactivation Trend Analysis

```sql
SELECT 
    DEACTIVATION_YEAR,
    DEACTIVATION_REASON_DESC,
    SUM(DEACTIVATION_COUNT) AS TOTAL_DEACTIVATIONS
FROM VW_DEACTIVATION_SUMMARY
WHERE DEACTIVATION_YEAR >= 2020
GROUP BY DEACTIVATION_YEAR, DEACTIVATION_REASON_DESC
ORDER BY DEACTIVATION_YEAR DESC, TOTAL_DEACTIVATIONS DESC;
```

---

## Common Use Cases

### Healthcare Analytics
- Provider network adequacy analysis
- Specialty distribution mapping
- Market opportunity identification
- Competitive landscape analysis

### Payer Operations
- Provider credentialing verification
- Network directory maintenance
- Claims validation (NPI verification)
- Provider outreach targeting

### Healthcare IT
- Provider master data management
- EHR/EMR integration
- FHIR endpoint discovery
- Direct address lookup

### Life Sciences
- HCP targeting for medical affairs
- Clinical trial site identification
- Market access planning
- KOL identification

### Compliance
- Provider eligibility verification
- Medicare/Medicaid enrollment validation
- Sanctions screening support
- Audit trail maintenance

---

## Data Refresh Schedule

| Event | Timing |
|-------|--------|
| CMS NPPES Release | 1st week of each month |
| Data Processing | Within 3 business days of CMS release |
| Listing Update | Within 5 business days of CMS release |
| Taxonomy Reference Update | Quarterly (aligned with NUCC releases) |

---

## Data Limitations

1. **No Historical Versioning**: This listing provides current snapshot only. Historical changes are not preserved.

2. **Self-Reported Data**: NPPES data is self-reported by providers and may contain inaccuracies.

3. **Masked Identifiers**: Some legacy identifiers (Medicare UPIN, etc.) may be masked with placeholder characters.

4. **Address Accuracy**: Addresses are not validated against USPS or geocoded.

5. **Deactivation Lag**: There may be a delay between actual practice closure and NPI deactivation.

6. **Taxonomy Completeness**: Not all providers have complete taxonomy information.

---

## Terms of Use

This data is derived from publicly available CMS NPPES data. Users must comply with:

1. CMS NPPES Terms of Use
2. HIPAA regulations (this data does not contain PHI)
3. Applicable state and federal privacy laws

**Prohibited Uses**:
- Direct marketing to individuals without consent
- Discriminatory practices
- Any use that violates CMS guidelines

---

## Support

For questions about this data listing:

- **Technical Issues**: Contact via Snowflake Marketplace support
- **Data Questions**: Refer to CMS NPPES documentation
- **Taxonomy Questions**: Refer to NUCC website (https://nucc.org/)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-01 | Initial release |
| 1.1 | 2024-02 | Added DIM_PROVIDER_ENDPOINT table |
| 1.2 | 2024-03 | Added DIM_PROVIDER_IDENTIFIER table |
| 1.3 | 2024-04 | Added 18 analytical views |

---

*Last Updated: January 2025*
*Data Source Version: NPPES Monthly Extract*
