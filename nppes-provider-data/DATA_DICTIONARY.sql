/*
================================================================================
NPPES Healthcare Provider Data - Data Dictionary
Snowflake Marketplace Data Listing
================================================================================
*/

-- ============================================================================
-- QUICK REFERENCE: TABLE ROW COUNTS (Approximate)
-- ============================================================================
/*
| Table                      | Approx Rows  | Description                        |
|----------------------------|--------------|-------------------------------------|
| DIM_PROVIDER               | 8,500,000    | Core provider dimension             |
| DIM_PROVIDER_ADDRESS       | 17,000,000   | ~2 addresses per provider           |
| DIM_PROVIDER_TAXONOMY      | 12,000,000   | Up to 15 taxonomies per provider    |
| DIM_PROVIDER_IDENTIFIER    | 15,000,000   | Up to 50 identifiers per provider   |
| DIM_PROVIDER_ENDPOINT      | 3,000,000    | Digital endpoints                   |
| DIM_AUTHORIZED_OFFICIAL    | 1,500,000    | Type 2 org contacts                 |
| REF_TAXONOMY_CODE          | 900          | NUCC taxonomy reference             |
*/

-- ============================================================================
-- ENTITY RELATIONSHIP DIAGRAM (Mermaid)
-- ============================================================================
/*
```mermaid
erDiagram
    DIM_PROVIDER ||--o{ DIM_PROVIDER_ADDRESS : has
    DIM_PROVIDER ||--o{ DIM_PROVIDER_TAXONOMY : has
    DIM_PROVIDER ||--o{ DIM_PROVIDER_IDENTIFIER : has
    DIM_PROVIDER ||--o{ DIM_PROVIDER_ENDPOINT : has
    DIM_PROVIDER ||--o| DIM_AUTHORIZED_OFFICIAL : has
    DIM_PROVIDER_TAXONOMY }o--|| REF_TAXONOMY_CODE : references
    DIM_PROVIDER }o--o| REF_TAXONOMY_CODE : primary_taxonomy
    
    DIM_PROVIDER {
        number PROVIDER_SK PK
        varchar NPI UK
        varchar ENTITY_TYPE_CODE
        varchar PRIMARY_TAXONOMY_CODE FK
        boolean IS_ACTIVE
    }
    
    DIM_PROVIDER_ADDRESS {
        number ADDRESS_SK PK
        number PROVIDER_SK FK
        varchar ADDRESS_TYPE_CODE
        varchar STATE_CODE
    }
    
    DIM_PROVIDER_TAXONOMY {
        number TAXONOMY_SK PK
        number PROVIDER_SK FK
        varchar TAXONOMY_CODE FK
        boolean IS_PRIMARY_TAXONOMY
    }
    
    REF_TAXONOMY_CODE {
        varchar TAXONOMY_CODE PK
        varchar TAXONOMY_CLASSIFICATION
        varchar TAXONOMY_SPECIALIZATION
    }
```
*/

-- ============================================================================
-- CODE VALUE REFERENCE
-- ============================================================================

-- ENTITY_TYPE_CODE (DIM_PROVIDER)
/*
| Code | Description  | Details                                    |
|------|--------------|---------------------------------------------|
| 1    | Individual   | Healthcare professionals (physicians, etc.) |
| 2    | Organization | Healthcare facilities, groups, agencies     |
*/

-- PROVIDER_SEX_CODE (DIM_PROVIDER)
/*
| Code | Description |
|------|-------------|
| M    | Male        |
| F    | Female      |
| NULL | Not provided / Organization |
*/

-- DEACTIVATION_REASON_CODE (DIM_PROVIDER)
/*
| Code | Description  | Details                              |
|------|--------------|---------------------------------------|
| DT   | Death        | Provider deceased                     |
| DB   | Disbandment  | Organization dissolved                |
| FR   | Fraud        | Fraudulent activity                   |
| OT   | Other        | Other reason                          |
| NULL | Active       | NPI is currently active               |
*/

-- IS_SOLE_PROPRIETOR (DIM_PROVIDER)
/*
| Code | Description   |
|------|---------------|
| Y    | Yes           |
| N    | No            |
| X    | Not Answered  |
*/

-- ADDRESS_TYPE_CODE (DIM_PROVIDER_ADDRESS)
/*
| Code     | Description               |
|----------|---------------------------|
| MAILING  | Business Mailing Address  |
| PRACTICE | Primary Practice Location |
*/

-- IDENTIFIER_TYPE_CODE (DIM_PROVIDER_IDENTIFIER)
/*
| Code | Description                    | Program      |
|------|--------------------------------|--------------|
| 01   | Other (non-Medicare)           | Various      |
| 02   | Medicare UPIN                  | Medicare     |
| 04   | Medicare ID-Type Unspecified   | Medicare     |
| 05   | Medicaid                       | Medicaid     |
| 06   | Medicare OSCAR/Certification   | Medicare     |
| 07   | Medicare NSC                   | Medicare     |
| 08   | Medicare PIN                   | Medicare     |
*/

-- ENDPOINT_PROTOCOL (DIM_PROVIDER_ENDPOINT - Derived)
/*
| Code   | Description               |
|--------|---------------------------|
| HTTPS  | Secure HTTP endpoint      |
| HTTP   | Non-secure HTTP endpoint  |
| DIRECT | Direct messaging address  |
| OTHER  | Other protocol            |
*/

-- ============================================================================
-- DERIVED COLUMN FORMULAS
-- ============================================================================

-- DIM_PROVIDER.ENTITY_TYPE_DESC
/*
CASE ENTITY_TYPE_CODE 
    WHEN '1' THEN 'Individual'
    WHEN '2' THEN 'Organization'
    ELSE 'Unknown'
END
*/

-- DIM_PROVIDER.PROVIDER_FULL_NAME
/*
TRIM(
    COALESCE(PROVIDER_NAME_PREFIX || ' ', '') ||
    COALESCE(PROVIDER_FIRST_NAME || ' ', '') ||
    COALESCE(PROVIDER_MIDDLE_NAME || ' ', '') ||
    COALESCE(PROVIDER_LAST_NAME, '') ||
    COALESCE(' ' || PROVIDER_NAME_SUFFIX, '') ||
    COALESCE(', ' || PROVIDER_CREDENTIAL, '')
)
*/

-- DIM_PROVIDER.IS_ACTIVE
/*
CASE 
    WHEN DEACTIVATION_DATE IS NULL THEN TRUE
    WHEN REACTIVATION_DATE IS NOT NULL THEN TRUE
    ELSE FALSE
END
*/

-- DIM_PROVIDER_ADDRESS.POSTAL_CODE_5
/*
LEFT(REPLACE(POSTAL_CODE, '-', ''), 5)
*/

-- DIM_PROVIDER_ADDRESS.POSTAL_CODE_4
/*
CASE WHEN LENGTH(REPLACE(POSTAL_CODE, '-', '')) >= 9 
     THEN SUBSTR(REPLACE(POSTAL_CODE, '-', ''), 6, 4) 
     ELSE NULL 
END
*/

-- DIM_PROVIDER_ADDRESS.IS_US_ADDRESS
/*
COUNTRY_CODE IS NULL OR COUNTRY_CODE = 'US'
*/

-- DIM_PROVIDER_ADDRESS.TELEPHONE_DIGITS
/*
REGEXP_REPLACE(TELEPHONE_NUMBER, '[^0-9]', '')
*/

-- DIM_PROVIDER_ADDRESS.FULL_ADDRESS
/*
TRIM(
    COALESCE(ADDRESS_LINE_1 || ', ', '') ||
    COALESCE(ADDRESS_LINE_2 || ', ', '') ||
    COALESCE(CITY_NAME || ', ', '') ||
    COALESCE(STATE_CODE || ' ', '') ||
    COALESCE(POSTAL_CODE, '')
)
*/

-- DIM_PROVIDER_ENDPOINT.ENDPOINT_PROTOCOL
/*
CASE 
    WHEN UPPER(ENDPOINT) LIKE 'HTTPS://%' THEN 'HTTPS'
    WHEN UPPER(ENDPOINT) LIKE 'HTTP://%' THEN 'HTTP'
    WHEN UPPER(ENDPOINT) LIKE '%@DIRECT.%' OR UPPER(ENDPOINT_TYPE) LIKE '%DIRECT%' THEN 'DIRECT'
    ELSE 'OTHER'
END
*/

-- DIM_PROVIDER_ENDPOINT.IS_FHIR_ENDPOINT
/*
UPPER(ENDPOINT_TYPE) LIKE '%FHIR%' OR UPPER(ENDPOINT_DESCRIPTION) LIKE '%FHIR%'
*/

-- DIM_PROVIDER_IDENTIFIER.IS_MASKED
/*
REGEXP_LIKE(IDENTIFIER_VALUE, '^[\\$\\*\\=]{9}$')
-- Matches values like '$$$$$$$$$', '*********', '========='
*/

-- ============================================================================
-- KEY RELATIONSHIPS
-- ============================================================================

/*
PRIMARY KEYS:
- DIM_PROVIDER.PROVIDER_SK (surrogate)
- DIM_PROVIDER.NPI (natural/business key)
- DIM_PROVIDER_ADDRESS.ADDRESS_SK
- DIM_PROVIDER_TAXONOMY.TAXONOMY_SK
- DIM_PROVIDER_IDENTIFIER.IDENTIFIER_SK
- DIM_PROVIDER_ENDPOINT.ENDPOINT_SK
- DIM_AUTHORIZED_OFFICIAL.AUTHORIZED_OFFICIAL_SK
- REF_TAXONOMY_CODE.TAXONOMY_CODE

FOREIGN KEYS:
- DIM_PROVIDER_ADDRESS.NPI → DIM_PROVIDER.NPI
- DIM_PROVIDER_ADDRESS.PROVIDER_SK → DIM_PROVIDER.PROVIDER_SK
- DIM_PROVIDER_TAXONOMY.NPI → DIM_PROVIDER.NPI
- DIM_PROVIDER_TAXONOMY.TAXONOMY_CODE → REF_TAXONOMY_CODE.TAXONOMY_CODE
- DIM_PROVIDER_IDENTIFIER.NPI → DIM_PROVIDER.NPI
- DIM_PROVIDER_ENDPOINT.NPI → DIM_PROVIDER.NPI
- DIM_AUTHORIZED_OFFICIAL.NPI → DIM_PROVIDER.NPI
- DIM_PROVIDER.PRIMARY_TAXONOMY_CODE → REF_TAXONOMY_CODE.TAXONOMY_CODE

CARDINALITY:
- DIM_PROVIDER : DIM_PROVIDER_ADDRESS = 1:N (typically 1:2)
- DIM_PROVIDER : DIM_PROVIDER_TAXONOMY = 1:N (max 1:15)
- DIM_PROVIDER : DIM_PROVIDER_IDENTIFIER = 1:N (max 1:50)
- DIM_PROVIDER : DIM_PROVIDER_ENDPOINT = 1:N
- DIM_PROVIDER : DIM_AUTHORIZED_OFFICIAL = 1:0..1 (Type 2 only)
*/

-- ============================================================================
-- INDEXING RECOMMENDATIONS (for consumers)
-- ============================================================================

/*
RECOMMENDED INDEXES FOR QUERY PERFORMANCE:

-- Primary lookups
CREATE INDEX IF NOT EXISTS IDX_PROVIDER_NPI ON DIM_PROVIDER(NPI);
CREATE INDEX IF NOT EXISTS IDX_PROVIDER_TAXONOMY ON DIM_PROVIDER(PRIMARY_TAXONOMY_CODE);

-- Address queries
CREATE INDEX IF NOT EXISTS IDX_ADDRESS_NPI ON DIM_PROVIDER_ADDRESS(NPI);
CREATE INDEX IF NOT EXISTS IDX_ADDRESS_STATE ON DIM_PROVIDER_ADDRESS(STATE_CODE);
CREATE INDEX IF NOT EXISTS IDX_ADDRESS_ZIP ON DIM_PROVIDER_ADDRESS(POSTAL_CODE_5);

-- Taxonomy queries  
CREATE INDEX IF NOT EXISTS IDX_TAX_NPI ON DIM_PROVIDER_TAXONOMY(NPI);
CREATE INDEX IF NOT EXISTS IDX_TAX_CODE ON DIM_PROVIDER_TAXONOMY(TAXONOMY_CODE);

-- Search queries
CREATE INDEX IF NOT EXISTS IDX_PROVIDER_LAST_NAME ON DIM_PROVIDER(PROVIDER_LAST_NAME);
CREATE INDEX IF NOT EXISTS IDX_PROVIDER_ORG_NAME ON DIM_PROVIDER(ORGANIZATION_NAME_LBN);
*/

-- ============================================================================
-- COMMON QUERY PATTERNS
-- ============================================================================

-- Pattern 1: Provider lookup with full details
/*
SELECT p.*, t.TAXONOMY_CLASSIFICATION, a.FULL_ADDRESS
FROM DIM_PROVIDER p
LEFT JOIN REF_TAXONOMY_CODE t ON p.PRIMARY_TAXONOMY_CODE = t.TAXONOMY_CODE
LEFT JOIN DIM_PROVIDER_ADDRESS a ON p.NPI = a.NPI AND a.ADDRESS_TYPE_CODE = 'PRACTICE'
WHERE p.NPI = '1234567890';
*/

-- Pattern 2: Active providers by state and specialty
/*
SELECT p.NPI, p.PROVIDER_FULL_NAME, t.TAXONOMY_CLASSIFICATION
FROM DIM_PROVIDER p
JOIN DIM_PROVIDER_ADDRESS a ON p.NPI = a.NPI AND a.ADDRESS_TYPE_CODE = 'PRACTICE'
JOIN REF_TAXONOMY_CODE t ON p.PRIMARY_TAXONOMY_CODE = t.TAXONOMY_CODE
WHERE p.IS_ACTIVE = TRUE
  AND a.STATE_CODE = 'CA'
  AND t.TAXONOMY_CLASSIFICATION = 'Internal Medicine';
*/

-- Pattern 3: Provider counts by state
/*
SELECT a.STATE_CODE, COUNT(DISTINCT p.NPI) AS PROVIDER_COUNT
FROM DIM_PROVIDER p
JOIN DIM_PROVIDER_ADDRESS a ON p.NPI = a.NPI AND a.ADDRESS_TYPE_CODE = 'PRACTICE'
WHERE p.IS_ACTIVE = TRUE
GROUP BY a.STATE_CODE
ORDER BY PROVIDER_COUNT DESC;
*/

-- Pattern 4: Multi-specialty providers
/*
SELECT p.NPI, p.PROVIDER_FULL_NAME, COUNT(*) AS TAXONOMY_COUNT
FROM DIM_PROVIDER p
JOIN DIM_PROVIDER_TAXONOMY pt ON p.NPI = pt.NPI
GROUP BY p.NPI, p.PROVIDER_FULL_NAME
HAVING COUNT(*) > 1
ORDER BY TAXONOMY_COUNT DESC;
*/

-- ============================================================================
-- DATA QUALITY NOTES
-- ============================================================================

/*
KNOWN DATA QUALITY CONSIDERATIONS:

1. NULL Values:
   - PRIMARY_TAXONOMY_CODE: ~2% of providers have no taxonomy
   - PROVIDER_SEX_CODE: NULL for all Type 2 organizations
   - EIN: Only populated for some Type 2 organizations
   
2. Address Completeness:
   - ~99% of providers have at least one address
   - ~95% have both mailing and practice addresses
   - STATE_CODE may be full state name for some legacy records
   
3. Identifier Masking:
   - Legacy Medicare identifiers (UPIN, OSCAR, PIN) may be masked
   - Masked values appear as '$$$$$$$$$', '*********', or '========='
   
4. Endpoint Coverage:
   - ~15% of organizations have registered endpoints
   - FHIR endpoints are growing but still limited coverage
   
5. Taxonomy Accuracy:
   - Self-reported by providers
   - May not reflect current practice specialty
   - Some providers have inactive/retired taxonomy codes
   
6. Date Fields:
   - ENUMERATION_DATE: Always populated
   - LAST_UPDATE_DATE: May be same as ENUMERATION_DATE if never updated
   - DEACTIVATION_DATE: Only populated for deactivated NPIs
*/

-- ============================================================================
-- CHANGE LOG
-- ============================================================================

/*
| Date       | Version | Change Description                          |
|------------|---------|---------------------------------------------|
| 2024-01-01 | 1.0.0   | Initial data model release                  |
| 2024-02-01 | 1.1.0   | Added DIM_PROVIDER_ENDPOINT table           |
| 2024-03-01 | 1.2.0   | Added DIM_PROVIDER_IDENTIFIER table         |
| 2024-04-01 | 1.3.0   | Added 18 analytical views                   |
| 2024-05-01 | 1.3.1   | Fixed TAXONOMY_GROUP truncation             |
| 2025-01-01 | 1.4.0   | Added REF_TAXONOMY_CODE staging             |
*/
