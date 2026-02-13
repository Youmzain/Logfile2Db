SELECT *
    FROM perf_file pf
    ORDER BY pf.created desc;

SELECT pr.perf_file_id, count(*)
    FROM perf_row pr
    WHERE pr.perf_file_id IN (21, 21)
        AND pr.file_row like '%org.apache.fontbox%'
        --AND pr.file_row like '%DEBUG org.apache.fontbox.util.autodetect.FontFileFinder - [] checkFontfile check C:\WINDOWS\FONTS\%'
        --AND pr.file_row like '%execute prepared%'
        --AND pr.file_row like '%[AWT-EventQueue-1] DEBUG com.agfa.orbis.billing.servicecapture.validation.SCSettingsRepository - [] Check SC_SETTINGS_null, (CatalogIdentifierGeneric)DRGABRA.301.01.01.2000 00:00:00(dbuid:359741), null%' 
        --AND   pr.file_row like '%[AWT-EventQueue-1] WARN com.agfa.orbis.billing.servicecapture.validation.SCSettingsRepository - [] Call with null values -> false%' 
        AND length(pr.file_row) > 1
    GROUP BY pr.perf_file_id
--    ORDER BY pr.perf_file_id, pr.row_number
;        

delete from perf_file where not id in (21, 22);

SELECT pr.perf_file_id, count(*)
    FROM perf_row pr
    WHERE pr.perf_file_id IN (21, 22)
        AND pr.file_row like '%org.apache.fontbox%'
        --AND pr.file_row like '%execute prepared%'
        --AND pr.file_row like '%[AWT-EventQueue-1] DEBUG com.agfa.orbis.billing.servicecapture.validation.SCSettingsRepository - [] Check SC_SETTINGS_null, (CatalogIdentifierGeneric)DRGABRA.301.01.01.2000 00:00:00(dbuid:359741), null%' 
        --AND   pr.file_row like '%[AWT-EventQueue-1] WARN com.agfa.orbis.billing.servicecapture.validation.SCSettingsRepository - [] Call with null values -> false%' 
        AND length(pr.file_row) > 1
        AND pr.row_number between 100008 and 115556
    GROUP BY pr.perf_file_id
--    ORDER BY pr.perf_file_id, pr.row_number
;        

WITH parsed AS (
    SELECT
        CAST(
            REGEXP_SUBSTR(pr.file_row, 'select\s*(\w+)', 1, 1, 'i', 1)
            AS VARCHAR2(100)
        ) AS selected_object
    FROM perf_row pr
    WHERE pr.perf_file_id = 21
      AND pr.file_row LIKE '%select%'
      AND REGEXP_LIKE(pr.file_row, 'select\s*\w+', 'i')
      AND LENGTH(pr.file_row) > 1
)
SELECT
    selected_object,
    COUNT(*) AS occurrences
FROM parsed
GROUP BY selected_object
ORDER BY occurrences DESC;



SELECT *
    FROM perf_row pr
    WHERE pr.perf_file_id IN (21, 21)
        AND pr.file_row like '%select result%'
        AND length(pr.file_row) > 1
    ORDER BY pr.perf_file_id, pr.row_number
;      


SELECT *
    FROM perf_row pr
    WHERE pr.perf_file_id IN (21, 21)
        AND pr.file_row like '%lookup select result of list com.agfa.hap.base.catalog.LstCatalogs in cache: com.agfa.hap.base.catalog.LstCatalogs:com.agfa.hap.base.SimpleListElementFactory:454de85fc3fd9524affd586c0786fed1fcdce51b %'
        AND length(pr.file_row) > 1
    ORDER BY pr.perf_file_id, pr.row_number
;      
