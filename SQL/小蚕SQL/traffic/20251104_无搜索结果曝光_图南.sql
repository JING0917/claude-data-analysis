-- 搜索漏斗基础数据
WITH search_data AS
  (SELECT to_date(time) AS search_date
          ,DATE_TRUNC('minute', time) AS search_time
          ,event
          ,distinct_id AS user_id
          ,entrance
          ,search_method
          ,query_word
          -- ,activity_id
          -- ,position
          -- ,search_word
          -- ,from_sourc
   FROM events
   WHERE to_date(time) = date_add(current_date(),interval -1 DAY)
     AND event IN ('Search_Click'
                   ,'Search_Result_Ex'
                   -- ,'Search_Result_Click'
                   -- ,'Intelligence_Activity_Id_Impression'
                   -- ,'Intelligence_Activity_Id_Click'
                   -- ,'Takeaway_Detailpage_View'
                   -- ,'Takeaway_Baomingflow_Button_Click'
                   -- ,'Takeaway_Orderflow_Button_Click'
                   )
     AND entrance in ('主页','首页')),



-- 搜索
WITH search_data AS
  (SELECT to_date(time) AS search_date,
          DATE_TRUNC('minute', time) AS search_time,
          distinct_id AS user_id,
          search_method,
          query_word,
          count(1) search_num
   FROM events
   WHERE to_date(time) = date_add(current_date(),interval -1 DAY)
     AND event='Search_Click'
     AND entrance IN ('主页',
                      '首页')
   GROUP BY 1,
            2,
            3,
            4,
            5),




-- 搜索结果曝光
search_result_data AS
  (SELECT to_date(time) AS search_date,
          DATE_TRUNC('minute', time) AS search_time,
          distinct_id AS user_id,
          search_method,
          query_word,
          count(1) search_exp_num
   FROM events
   WHERE to_date(time) = date_add(current_date(),interval -1 DAY)
     AND event='Search_Result_Ex'
     AND entrance IN ('主页',
                      '首页')
   GROUP BY 1,
            2,
            3,
            4,
            5)

-- 无搜索结果
SELECT a.search_date `搜索日期`,
       a.query_word `搜索词`,
       count(DISTINCT a.user_id) `搜索用户量`,
       count(DISTINCT if(b.user_id IS NULL,a.user_id,NULL)) `无搜索结果用户量`,
       count(DISTINCT if(b.user_id IS NULL,a.user_id,NULL))/count(DISTINCT a.user_id) `无搜索结果率`
FROM search_data a
LEFT JOIN search_result_data b ON a.search_time=b.search_time
AND a.user_id=b.user_id
AND a.search_method=b.search_method
AND a.query_word=b.query_word
GROUP BY 1,
         2;


============ 验证数据
-- distinct_id:488887277

-- 搜索
WITH search_data AS
  (SELECT to_date(time) AS search_date,
          DATE_TRUNC('minute', time) AS search_time,
          distinct_id AS user_id,
          search_method,
          query_word,
          count(1) search_num
   FROM events
   WHERE to_date(time) = date_add(current_date(),interval -1 DAY)
     AND event='Search_Click'
     AND entrance IN ('主页',
                      '首页')
     AND distinct_id='488887277'
   GROUP BY 1,
            2,
            3,
            4,
            5),


-- 搜索结果曝光
search_result_data AS
  (SELECT to_date(time) AS search_date,
          DATE_TRUNC('minute', time) AS search_time,
          distinct_id AS user_id,
          search_method,
          query_word,
          count(1) search_exp_num
   FROM events
   WHERE to_date(time) = date_add(current_date(),interval -1 DAY)
     AND event='Search_Result_Ex'
     AND entrance IN ('主页',
                      '首页')
   GROUP BY 1,
            2,
            3,
            4,
            5)

-- 无搜索结果
SELECT 
  a.*,b.*
FROM search_data a
LEFT JOIN search_result_data b ON a.search_time=b.search_time
AND a.user_id=b.user_id
AND a.search_method=b.search_method
AND a.query_word=b.query_word
;






