-- 月用户提现分位值
select
    ym,
    min(candou_amt) `最小提现金额`,
    percentile_cont(candou_amt,0.1) as `提现金额10分位`,
    percentile_cont(candou_amt,0.2) as `提现金额20分位`,
    percentile_cont(candou_amt,0.3) as `提现金额30分位`,
    percentile_cont(candou_amt,0.4) as `提现金额40分位`,
    percentile_cont(candou_amt,0.5) as `提现金额50分位`,
    percentile_cont(candou_amt,0.6) as `提现金额60分位`,
    percentile_cont(candou_amt,0.7) as `提现金额70分位`,
    percentile_cont(candou_amt,0.8) as `提现金额80分位`,
    percentile_cont(candou_amt,0.9) as `提现金额90分位`,
    percentile_cont(candou_amt,0.92) as `提现金额92分位`,
    percentile_cont(candou_amt,0.95) as `提现金额95分位`,
    percentile_cont(candou_amt,0.98) as `提现金额98分位`,
    max(candou_amt) `最大提现金额`,

    min(withdraw_num) `最小提现次数`,
    percentile_cont(withdraw_num,0.1) as `提现次数10分位`,
    percentile_cont(withdraw_num,0.2) as `提现次数20分位`,
    percentile_cont(withdraw_num,0.3) as `提现次数30分位`,
    percentile_cont(withdraw_num,0.4) as `提现次数40分位`,
    percentile_cont(withdraw_num,0.5) as `提现次数50分位`,
    percentile_cont(withdraw_num,0.6) as `提现次数60分位`,
    percentile_cont(withdraw_num,0.7) as `提现次数70分位`,
    percentile_cont(withdraw_num,0.8) as `提现次数80分位`,
    percentile_cont(withdraw_num,0.9) as `提现次数90分位`,
    percentile_cont(withdraw_num,0.92) as `提现次数92分位`,
    percentile_cont(withdraw_num,0.95) as `提现次数95分位`,
    percentile_cont(withdraw_num,0.98) as `提现次数98分位`,
    max(withdraw_num) `最大提现次数`
from
(select 
    date_format(created_at,'%Y-%m') as ym,
    silk_id,
    sum(amount/100) as candou_amt,
    count(1) as withdraw_num
from test.test_silkworm_client_withdraw_record 
where date_format(created_at,'%Y-%m-%d') >='2024-01-01'
    and status=1 -- 已审核
group by 1,2
) a
group by 1;


-- 月提现用户量
select 
    date_format(created_at,'%Y-%m') as ym,
    count(distinct silk_id) unum
from test.test_silkworm_client_withdraw_record 
where date_format(created_at,'%Y-%m-%d') >='2024-01-01'
    and status=1 -- 已审核
group by 1;









