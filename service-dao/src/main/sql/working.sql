﻿SET search_path TO supercharge, public;

-- =============================================================
-- user
-- =============================================================

select count(*) from users;

select * 
from users u
order by created_date desc;

select * from users where username in ('keith', 'xiujia');

select * from users where username not like 'temporary__%' order by modified_date desc;
select count(*) from users where username like 'temporary__%';

select u.user_id, u.username, u.created_date, u.email, r.role_name
from users u 
join user_role ur on u.user_id=ur.user_id 
join roles r on r.role_id = ur.role_id
where ur.role_id is not NULL
 AND u.username ='BTaylor32185'
order by username asc;

-- =============================================================
-- user_role
-- =============================================================

select * from user_role;

-- roles for a specific username
select u.user_id, u.username, string_agg(r.role_name, ',')
from users u
         left join user_role ur on ur.user_id = u.user_id
         join roles r on r.role_id = ur.role_id
where u.username = 'keith'
group by u.user_id, u.username;

select string_agg(r.role_name, ',')
from user_role ur
         join roles r on r.role_id = ur.role_id;


insert into user_role
values ((select user_id from users where username = 'BTaylor32185'),
        (select role_id from roles r where r.role_name = 'BTaylor32185'),
        now());

select *
from users
where user_id = 955185292;
select *
from users
where username = 'keith';

-- =============================================================
-- user_config
-- =============================================================

select count(*) from user_config;

-- most recently created user config rows joined with user.
select u.username, uc.* 
from user_config uc
join users u on u.user_id = uc.user_id
order by u.created_date desc;

-- most recently modified user config rows joined with user.
select u.username, uc.* 
from user_config uc
join users u on u.user_id = uc.user_id
order by uc.modified_date desc;

-- count of each map_zoom value
select map_zoom, count(*), 100.0 * count(*) / (select count(*) from user_config) as "percent"
from user_config GROUP BY map_zoom order by map_zoom asc;

-- counts of each unit: MI, KM
select unit, count(*) from user_config group by unit order by count(*) desc;

-- unused user_config rows
select count(*) from user_config where version=1 and map_zoom is null;
select * from user_config where version=1 and map_zoom is null order by modified_date desc;

-- =============================================================
-- login
-- =============================================================

select count(*) from login;

select count(*) from login where login_time >= NOW() - '1 day'::INTERVAL;

select distinct login.login_type from login;

select distinct login.result from login;

-- count of logins per user.
select u.username,count(*) 
from login l
join users u on u.user_id = l.user_id
group by u.username
order by count(*) desc;

-- count of logins per user -- WHERE RESULT IS INVALID_CREDENTIALS
select u.username,count(*) 
from login l
join users u on u.user_id = l.user_id
where l.result = 'INVALID_CREDENTIALS'
group by u.username
order by count(*) desc;

-- recent logins joined with user
select u.username, l.*
from login l
join users u on u.user_id = l.user_id
order by login_time desc;

-- recent logins joined with user -- FOR USERS WITH PRIVILEGES
select u.username, u.roles, l.*
from login l
join users u on u.user_id = l.user_id
where u.roles is not null and u.roles <> '' and u.username <> 'keith'
order by login_time desc;

-- =============================================================
-- user_reset_password
-- =============================================================

select count(*) from user_reset_password;

select u.username,* 
from user_reset_password urp
join users u on u.user_id = urp.user_id
order by request_time desc;


-- =============================================================
-- user_config_marker
-- =============================================================

select count(*) from user_config_marker;

select * from user_config_marker
order by created_date desc;

-- Lists the markers of each user.
select u.username, 
       u.user_id,
       max(ucm.created_date) as updated,
       count(*) as marker_count,
       string_agg(name, ',') as markers
from user_config_marker ucm
join users u on u.user_id = ucm.user_id
GROUP BY u.user_id
order by count(*) desc;


-- =============================================================
-- user_route / user_route_waypoint
-- =============================================================

-- routes by username
select u.username, u.user_id, u.created_date,
       ur.*,
       (select count(*) from user_route_waypoint urw where urw.route_id=ur.route_id)
from user_route ur
join users u on u.user_id=ur.user_id
order by u.username asc;

select * from user_route_waypoint;
select count(*) from user_route_waypoint;


-- =============================================================
-- country
-- =============================================================

select count(*) from country c;

select * from country c;

select * from country c where c.modified_date > '2019-11-15';

-- =============================================================
-- address
-- =============================================================


-- select addresses (and associated sites) by id.
select s.name,s.modified_date,s.opened_date, a.* 
from address a 
join site s on s.address_id = a.address_id
where a.address_id in(1000960,1000953);

-- count the number of sites in a specific country opened after a certain date
SELECT count(*)
FROM site s
JOIN address a ON a.address_id = s.address_id
JOIN country c ON c.country_id = a.country_id
WHERE s.counted = TRUE
AND s.opened_date > '2015-12-31' :: TIMESTAMP
AND c.name = 'USA';
      

      

-- =============================================================
-- site_change
-- =============================================================

select count(*) from site_change;      
      
-- Latest changes, joined with site name, and username.
SELECT s.name,u.username, sc.*
FROM site_change sc 
join site s on s.site_id =sc.site_id
join users u on u.user_id = sc.user_id
ORDER BY change_date DESC;

-- changes by user
SELECT u.username, count(*)
FROM site_change sc 
join site s on s.site_id =sc.site_id
join users u on u.user_id = sc.user_id
group BY u.username
order by count(*) desc;

-- Sites with the most changes.
select s.site_id, s.name, count(*) 
from site_change sc 
join site s on s.site_id = sc.site_id
group by s.site_id 
order by count(*) desc;

-- =============================================================
-- changelog
-- =============================================================

select count(*) from changelog;

select * 
from changelog 
order by modified_date desc;

select * from changelog where id=3350;
select * from changelog where site_id=1882;

update changelog set change_type='ADD' where id=3350;

-- ========================================================================================
-- This file just contains useful queries for working with tables in the schema.
-- ========================================================================================

--
-- Sixty day moving average of sites...still needs work.
--
select date(opened_date), t1 - t2 from
  (
    select s.opened_date,
      s.site_id,
      s.name,
      (select count(*)
       from site s2
       where s2.status = 'OPEN'
             and s2.opened_date <= s.opened_date
             and s2.counted = true) as t1,
      (select count(*)
       from site s3
       where s3.status = 'OPEN'
             and s3.opened_date <= s.opened_date - '60 day'::INTERVAL
             and s3.counted = true) as t2
    from site s
    where status='OPEN'
          and counted = true
    order by opened_date asc
  ) a;

  
-- ###########################################################################
--
-- scratch
--
-- ###########################################################################

select * from site where status='CLOSED_TEMP';

select * from site s limit 1;

select *
from site s
join address a on s.address_id=a.address_id
where 1=2
or
strpos(s.developer_notes, '>') > 0
or
strpos(s.developer_notes, '<') > 0
or
strpos(s."name", '>') > 0
or
strpos(s."name", '<') > 0
or
strpos(s.location_id, '>') > 0
or
strpos(s.location_id, '<') > 0
or
strpos(s.hours, '>') > 0
or
strpos(s.hours, '<') > 0
or
strpos(a.street, '>') > 0
or
strpos(a.street, '<') > 0
or
strpos(a.city, '>') > 0
or
strpos(a.city, '<') > 0
or
strpos(a.state, '>') > 0
or
strpos(a.state, '<') > 0
or
strpos(a.zip, '>') > 0
or
strpos(a.zip, '<') > 0
;


select * from users u where u.email ilike '%darren%';

select * from user_reset_password urp;

update users 
set password_salt = (select password_salt  from users u2 where u2.username='keith'),
    password_hash = (select password_hash  from users u2 where u2.username='keith')
    where user_id = 50598;
   
   
select version();   
   
   
   
