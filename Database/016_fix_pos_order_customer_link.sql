-- 016_fix_pos_order_customer_link.sql
-- One-time fix: relink a POS order to the correct customer by phone/name.
--
-- Default target in this script:
--   OrderNumber: ORD-20260327-CC6B8A77
--   Customer Name: Ashutosh Kumar
--   Customer Phone: 8130263026
--
-- Safe workflow:
-- 1) Run the preview SELECT blocks first.
-- 2) Confirm exactly one order + one target customer are matched.
-- 3) Keep the UPDATE block uncommented and run inside a transaction.

BEGIN;

-- ---------- PARAMETERS ----------
WITH params AS (
  SELECT
    'ORD-20260327-CC6B8A77'::text AS order_number,
    'Ashutosh Kumar'::text AS target_name,
    '8130263026'::text AS target_phone
)

-- ---------- PREVIEW: current order mapping ----------
SELECT
  o."OrderNumber",
  o."Id" AS "OrderId",
  o."CompanyId",
  o."CustomerId" AS "CurrentCustomerId",
  c."Name" AS "CurrentCustomerName",
  c."Phone" AS "CurrentCustomerPhone",
  c."Email" AS "CurrentCustomerEmail",
  o."OrderDate",
  o."TotalAmount",
  o."OrderSource",
  o."Status",
  o."PaymentStatus"
FROM "Orders" o
LEFT JOIN "Customers" c ON c."Id" = o."CustomerId"
JOIN params p ON p.order_number = o."OrderNumber";

-- ---------- PREVIEW: target customer candidates in same company ----------
WITH params AS (
  SELECT
    'ORD-20260327-CC6B8A77'::text AS order_number,
    'Ashutosh Kumar'::text AS target_name,
    '8130263026'::text AS target_phone
), order_ctx AS (
  SELECT o."CompanyId"
  FROM "Orders" o
  JOIN params p ON p.order_number = o."OrderNumber"
)
SELECT
  c."Id" AS "CandidateCustomerId",
  c."CompanyId",
  c."Name",
  c."Phone",
  c."Email",
  c."IsActive",
  c."TotalOrders"
FROM "Customers" c
JOIN order_ctx oc ON oc."CompanyId" = c."CompanyId"
JOIN params p ON 1 = 1
WHERE c."IsActive" = TRUE
  AND (
    lower(trim(c."Name")) = lower(trim(p.target_name))
    OR regexp_replace(coalesce(c."Phone", ''), '[^0-9]', '', 'g') = regexp_replace(p.target_phone, '[^0-9]', '', 'g')
  )
ORDER BY c."CreatedAtUtc" ASC;

-- ---------- APPLY FIX ----------
WITH params AS (
  SELECT
    'ORD-20260327-CC6B8A77'::text AS order_number,
    'Ashutosh Kumar'::text AS target_name,
    '8130263026'::text AS target_phone
), order_ctx AS (
  SELECT o."Id", o."CompanyId", o."CustomerId" AS old_customer_id
  FROM "Orders" o
  JOIN params p ON p.order_number = o."OrderNumber"
), target_customer AS (
  SELECT c."Id"
  FROM "Customers" c
  JOIN order_ctx oc ON oc."CompanyId" = c."CompanyId"
  JOIN params p ON 1 = 1
  WHERE c."IsActive" = TRUE
    AND (
      regexp_replace(coalesce(c."Phone", ''), '[^0-9]', '', 'g') = regexp_replace(p.target_phone, '[^0-9]', '', 'g')
      OR lower(trim(c."Name")) = lower(trim(p.target_name))
    )
  ORDER BY
    CASE
      WHEN regexp_replace(coalesce(c."Phone", ''), '[^0-9]', '', 'g') = regexp_replace((SELECT target_phone FROM params), '[^0-9]', '', 'g') THEN 0
      ELSE 1
    END,
    c."CreatedAtUtc" ASC
  LIMIT 1
), updated_order AS (
  UPDATE "Orders" o
  SET "CustomerId" = tc."Id",
      "UpdatedAtUtc" = NOW()
  FROM params p, target_customer tc
  WHERE o."OrderNumber" = p.order_number
  RETURNING o."Id", o."OrderNumber", o."CompanyId", o."CustomerId" AS new_customer_id
), touched_customers AS (
  SELECT old_customer_id AS customer_id FROM order_ctx
  UNION
  SELECT new_customer_id AS customer_id FROM updated_order
)
UPDATE "Customers" c
SET "TotalOrders" = (
    SELECT COUNT(*)::int
    FROM "Orders" o
    WHERE o."CustomerId" = c."Id" AND o."IsActive" = TRUE
  ),
  "UpdatedAtUtc" = NOW()
WHERE c."Id" IN (SELECT customer_id FROM touched_customers);

-- ---------- POST-CHECK ----------
WITH params AS (
  SELECT 'ORD-20260327-CC6B8A77'::text AS order_number
)
SELECT
  o."OrderNumber",
  o."CustomerId",
  c."Name" AS "LinkedCustomerName",
  c."Phone" AS "LinkedCustomerPhone",
  c."TotalOrders" AS "LinkedCustomerTotalOrders"
FROM "Orders" o
JOIN "Customers" c ON c."Id" = o."CustomerId"
JOIN params p ON p.order_number = o."OrderNumber";

COMMIT;
