============= dws_sr_store_takeawaypro_statis_d表中，存在销单量>活动名额数据
-- badcase
SELECT *
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt='2025-11-15'
  AND city_name='安庆市'
  AND county_name='宜秀区'
  AND promotion_quota<valid_order_num;


SELECT order_time,
       user_id,
       order_id,
       order_status
FROM dwd.dwd_sr_order_promotion_order
WHERE dt BETWEEN '2025-11-15' AND '2025-11-16'
  AND store_promotion_id=82575225;

