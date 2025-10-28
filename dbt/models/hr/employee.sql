{{ config(
    indexes = [
                {'columns':['employee_id'],'type':'btree'},
                {'columns':['deleted'],'type':'btree'} 
              ],
    unique_key = "employee_id",
    SCHEMA = 'hr'
) }}

SELECT 
	("Data"->>'id')::VARCHAR(24) AS employee_id,
	("Data"->'general'->>'id')::VARCHAR(24) AS employee_id_number,
    ("Data"->'general'->>'status')::VARCHAR(24) AS status, 
    CAST(TO_TIMESTAMP("Data"->'general'->>'dateOfJoining', 'YYYY-MM-DD"T"HH24:MI:SS.USZ') + INTERVAL '5 HOURS 30 MINUTES' AS DATE) AS date_of_joining, 
	("Data"->'employer'->>'branchId')::VARCHAR(24) AS branch_id, 
	("Data"->'employer'->>'companyId')::VARCHAR(24) AS company_id, 
	("Data"->'candidate'->>'id')::VARCHAR(24) AS user_id,  
    "_ab_cdc_deleted_at",
    CASE WHEN "_ab_cdc_deleted_at" IS NOT NULL THEN true ELSE false END::BOOLEAN AS deleted,
    "_ab_cdc_updated_at"::TIMESTAMP AS _ab_cdc_updated_at 
FROM {{source('public','Employee')}}  
WHERE 1 = 1
{% if is_incremental() %}
AND (
    "_ab_cdc_updated_at"::TIMESTAMP > (SELECT MAX("_ab_cdc_updated_at"::TIMESTAMP) FROM {{ this }})
    OR "_ab_cdc_deleted_at"::TIMESTAMP > COALESCE((SELECT MAX("_ab_cdc_deleted_at"::TIMESTAMP) FROM {{ this }}), 'epoch'::TIMESTAMP)
)
{% endif %}