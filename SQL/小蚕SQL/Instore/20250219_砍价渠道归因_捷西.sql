dim.dim_nca_channel_click -- 用户首次点击链接时间记录
dim.dim_silkworm_misc_channel -- 渠道信息表
dim.dim_silkworm_misc_func_channel -- 渠道信息表 -- 无数据，空表

-- 砍价渠道老用户
select
    case when channel_id in ( 1384, 1379, 1334, 1294, 1292, 1265, 1261, 1255, 1237, 1221, 1218, 1166, 1148, 1117) then '成都'
        when channel_id in (1338, 1293, 1271, 1260, 1256, 1244, 1153, 1149, 1116) then '广州'
        when channel_id in (1372,1367,1356,1353,1308,1214,1209) then '杭州'
        when channel_id in (1373, 1329, 1312, 1291, 1273, 1259, 1251, 1243, 1216, 1162, 1144, 1142, 1115) then '合肥'
        when channel_id in (1383, 1380, 1377, 1327, 1318, 1313, 1295, 1282, 1269, 1257, 1254, 1253, 1252, 1222, 1220, 
                            1219, 1217, 1155, 1151, 1150, 1113, 1112, 1111) then '上海'
        when channel_id in (1376,1331) then '深圳'
        when channel_id in (1274, 1357, 1333, 1332, 1310, 1281, 1270, 1258, 1250, 1238, 1215, 1159, 1145, 1114) then '武汉'
        when channel_id in (1336,1266,1239) then '长沙'
    else '其他' end as city_name,
    sum(bargain_finish_order_num) as bargain_finish_order_num,
    sum(bargain_order_profit) as bargain_order_profit
from dws.dws_sr_bargain_olduser_d
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and channel_id in (1384, 1383, 1380, 1379, 1377, 1376, 1373, 1372, 1367, 1357, 1356, 1353, 1338, 1336, 1334,
    1333, 1332, 1331, 1329, 1327, 1318, 1313, 1312, 1310, 1308, 1295, 1294, 1293, 1292, 1291, 1282, 1281, 1274,
    1273, 1271, 1270, 1269, 1266, 1265, 1261, 1260, 1259, 1258, 1257, 1256, 1255, 1254, 1253, 1252, 1251, 1250,
    1244, 1243, 1239, 1238, 1237, 1222, 1221, 1220, 1219, 1218, 1217, 1216, 1215, 1214, 1209, 1166, 1162, 1159,
    1155, 1153, 1151, 1150, 1149, 1148, 1145, 1144, 1142, 1117, 1116, 1115, 1114, 1113, 1112, 1111)
group by 1
;



=================== 正式跑数

-- 渠道链接点击
drop view if exists channel_clc;
create view IF NOT EXISTS channel_clc (
    user_id,event_time,channel_information
)
 as (
SELECT
        user_id,
        event_time,
        channel_information
FROM (
    SELECT
        user_id,
        FROM_UNIXTIME(LEFT(event_time, 10), '%Y-%m-%d %H:%i:%s') as event_time,
        get_json_object(data, "$.channel_information") as channel_information,
        row_number() OVER(PARTITION BY user_id ORDER BY event_time) as clc_rank
    FROM
        ods.ods_sr_event_log -- 日志表数据量较大，谨慎使用
    WHERE
        dt between '2025-02-17' and '2025-02-23'
            and event_name = 'Open_Link'
            and user_id regexp '^[0-9]{1,10}$'
    ) a
where clc_rank=1
);


drop view if exists channel_user;
create view IF NOT EXISTS channel_user (
    user_id,event_time,channel_information,channel_id
)
 as (
select
    user_id,
    event_time,
    channel_information,
    COALESCE(b.auto_id,0) as channel_id
from channel_clc
LEFT JOIN dim.dim_silkworm_misc_channel AS b --渠道信息表
ON channel_clc.channel_information = b.param
);



drop view if exists order_info;
create view IF NOT EXISTS order_info (
    user_id,order_num,pay_order_num,verify_order_num,finish_order_num
)
 as (
select
    user_id
    ,count(distinct order_id ) as order_num
    ,count(distinct case when substr(pay_time,1,10)<> '1970-01-01' then order_id end) as pay_order_num
    ,count(distinct case when substr(verify_time,1,10)<> '1970-01-01' then order_id end) as verify_order_num
    ,count(distinct case when status=5 then order_id end) as finish_order_num
from 
    dwd.dwd_sr_silkworm_explore_order
where 
    dt between '2025-02-17' and date_sub(current_date(),interval 1 day)
    and promotion_type=5
group by user_id
);


select
    -- channel_id,
    case when channel_id in (1980, 1904, 1886, 1881, 1767, 1713, 1692, 1639, 1622, 1556, 1531, 1521, 1520, 1490, 1457, 1456, 1452, 1396, 1484) then '成都'
        when channel_id in (2014, 1948, 1907, 1906, 1876, 1800, 1706, 1667, 1641, 1625, 1546, 1527, 1522, 1494, 1467, 1459, 1430, 1419) then '广州'
        when channel_id in (1534, 2010, 1961, 1900, 1892, 1827, 1735, 1721, 1710, 1632, 1617, 1539, 1537, 1535, 1518, 1454, 1450) then '杭州'
        when channel_id in (2035, 2002, 1978, 1974, 1929, 1861, 1841, 1793, 1779, 1748, 1746, 1733, 1677, 1676, 1669, 1602, 1601, 1567, 1525, 1512, 1507, 1475, 1427, 1416) then '合肥'
        when channel_id in (2016, 2013, 1985, 1933, 1908, 1865, 1863, 1862, 1829, 1794, 1753, 1700, 1657, 1655, 1651, 1649, 1648, 1647, 1640, 1629, 1627, 1626, 1594, 1542, 1536, 1519, 1486, 1485, 1460, 1458, 1438, 1395, 1394, 1393, 1392, 1391) then '上海'
        when channel_id in (2041, 1981, 1919, 1847, 1810, 1741, 1691, 1620, 1574, 1532, 1517, 1514, 1501, 1483, 1437, 1428, 1412, 1406, 1401) then '深圳'
        when channel_id in (2024, 2008, 1965, 1962, 1945, 1940, 1936, 1931, 1835, 1762, 1752, 1682, 1597, 1560, 1509, 1470, 1425, 1418) then '武汉'
        when channel_id in (2012, 1869, 1814, 1754, 1644, 1549, 1548, 1487, 1397) then '长沙'
    else '其他' end as city_name,
    case when channel_id in (1520, 1457, 1456, 1522, 1459, 2010, 1892, 1735, 1454, 1978, 1974, 1841, 1748, 1746, 1602, 1601, 1525, 1512, 1427, 2013, 1865, 1651, 1649, 1648, 1647, 1629, 1627, 1626, 1519, 1395, 1394, 1981, 1847, 1741, 1620, 1532, 1517, 1514, 1428, 1965, 1962, 1752, 1597, 1509, 1425) then '企微'
        when channel_id in (1980, 1904, 1886, 1881, 1767, 1713, 1692, 1639, 1622, 1556, 1531, 1521, 1490, 1452, 1396, 1484, 2014, 1948, 1907, 1906, 1876, 1800, 1706, 1667, 1641, 1625, 1546, 1527, 1494, 1467, 1430, 1419, 1534, 1961, 1900, 1827, 1721, 1710, 1632, 1617, 1539, 1537, 1535, 1518, 1450, 2035, 2002, 1929, 1861, 1793, 1779, 1733, 1677, 1676, 1669, 1567, 1507, 1475, 1416, 2016, 1985, 1933, 1908, 1863, 1862, 1829, 1794, 1753, 1700, 1657, 1655, 1640, 1594, 1542, 1536, 1486, 1485, 1460, 1458, 1438, 1393, 1392, 1391, 2041, 1919, 1810, 1691, 1574, 1501, 1483, 1437, 1412, 1406, 1401, 2024, 2008, 1945, 1940, 1936, 1931, 1835, 1762, 1682, 1560, 1470, 1418, 2012, 1869, 1814, 1754, 1644, 1549, 1548, 1487, 1397) then '社群'
    else '其他' end as channel_typename,
    count(distinct channel_user.user_id) as unum,
    count(distinct if(order_num>=1,channel_user.user_id,null)) as order_unum,
    sum(order_num) as order_num,
    sum(pay_order_num) as pay_order_num,
    sum(verify_order_num) as verify_order_num,
    sum(finish_order_num) as finish_order_num
from channel_user left join order_info on channel_user.user_id=order_info.user_id
where channel_id in (1980, 1904, 1886, 1881, 1767, 1713, 1692, 1639, 1622, 1556, 1531, 1521, 1520, 1490, 1457, 1456, 1452, 1396, 1484,2014, 1948, 1907, 1906, 1876, 1800, 1706, 1667, 1641, 1625, 1546, 1527, 1522, 1494, 1467, 1459, 1430, 1419,1534, 2010, 1961, 1900, 1892, 1827, 1735, 1721, 1710, 1632, 1617, 1539, 1537, 1535, 1518, 1454, 1450,2035, 2002, 1978, 1974, 1929, 1861, 1841, 1793, 1779, 1748, 1746, 1733, 1677, 1676, 1669, 1602, 1601, 1567, 1525, 1512, 1507, 1475, 1427, 1416,2016, 2013, 1985, 1933, 1908, 1865, 1863, 1862, 1829, 1794, 1753, 1700, 1657, 1655, 1651, 1649, 1648, 1647, 1640, 1629, 1627, 1626, 1594, 1542, 1536, 1519, 1486, 1485, 1460, 1458, 1438, 1395, 1394, 1393, 1392, 1391,2041, 1981, 1919, 1847, 1810, 1741, 1691, 1620, 1574, 1532, 1517, 1514, 1501, 1483, 1437, 1428, 1412, 1406, 1401,2024, 2008, 1965, 1962, 1945, 1940, 1936, 1931, 1835, 1762, 1752, 1682, 1597, 1560, 1509, 1470, 1425, 1418,2012, 1869, 1814, 1754, 1644, 1549, 1548, 1487, 1397)
group by 1,2;




-- 城市砍价订单
select
    city_name
    ,count(distinct user_id) as order_user_num
    ,count(distinct order_id ) as order_num
    ,count(distinct case when substr(pay_time,1,10)<> '1970-01-01' then order_id end) as pay_order_num
    ,count(distinct case when substr(verify_time,1,10)<> '1970-01-01' then order_id end) as verify_order_num
    ,count(distinct case when a.status=5 then order_id end) as finish_order_num
from 
    dwd.dwd_sr_silkworm_explore_order a
left join dim.dim_silkworm_explore_store b on a.store_id=b.store_id and b.city_name in ('成都市','广州市','杭州市','合肥市','上海市','深圳市','武汉市','长沙市')
where 
    a.dt between '2025-02-17' and date_sub(current_date(),interval 1 day)
    and a.promotion_type=5
group by 1;

























