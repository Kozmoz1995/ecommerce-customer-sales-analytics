/*
  One analytical location per postcode prefix.

  Rules
  -----
  1. Average latitude and longitude for the postcode prefix.
  2. Select the most frequently occurring city/state pair.
  3. Retain source row count as a data-quality indicator.
  4. Use deterministic alphabetical tie-breaking.
*/

USE EcommerceAnalytics;
GO

DROP TABLE IF EXISTS analytics.dim_geolocation;
GO

WITH valid_geo AS
(
    SELECT
        geolocation_zip_code_prefix AS zip_code_prefix,
        TRY_CONVERT(decimal(10, 7), geolocation_lat) AS latitude,
        TRY_CONVERT(decimal(10, 7), geolocation_lng) AS longitude,
        NULLIF(LTRIM(RTRIM(geolocation_city)), '') AS city,
        UPPER(NULLIF(LTRIM(RTRIM(geolocation_state)), '')) AS state
    FROM staging.geolocation
    WHERE TRY_CONVERT(decimal(10, 7), geolocation_lat) BETWEEN -90 AND 90
      AND TRY_CONVERT(decimal(10, 7), geolocation_lng) BETWEEN -180 AND 180
),
coordinate_summary AS
(
    SELECT
        zip_code_prefix,
        AVG(latitude) AS latitude,
        AVG(longitude) AS longitude,
        COUNT_BIG(*) AS source_row_count
    FROM valid_geo
    GROUP BY zip_code_prefix
),
city_state_frequency AS
(
    SELECT
        zip_code_prefix,
        city,
        state,
        COUNT_BIG(*) AS frequency,
        ROW_NUMBER() OVER
        (
            PARTITION BY zip_code_prefix
            ORDER BY COUNT_BIG(*) DESC, state ASC, city ASC
        ) AS preference_rank
    FROM valid_geo
    WHERE city IS NOT NULL AND state IS NOT NULL
    GROUP BY zip_code_prefix, city, state
)
SELECT
    IDENTITY(int, 1, 1) AS geolocation_key,
    c.zip_code_prefix,
    c.latitude,
    c.longitude,
    f.city,
    f.state,
    c.source_row_count,
    f.frequency AS selected_city_state_count
INTO analytics.dim_geolocation
FROM coordinate_summary c
LEFT JOIN city_state_frequency f
    ON f.zip_code_prefix = c.zip_code_prefix
   AND f.preference_rank = 1;
GO

ALTER TABLE analytics.dim_geolocation
ADD CONSTRAINT PK_dim_geolocation PRIMARY KEY CLUSTERED (geolocation_key);

CREATE UNIQUE INDEX UX_dim_geolocation_zip
    ON analytics.dim_geolocation (zip_code_prefix);
GO

