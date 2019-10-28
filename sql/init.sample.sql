create database dakoku;

create table tokens (id SERIAL, access_token varchar(255), refresh_token varchar(255), expires_at varchar(255));

insert into tokens (access_token, refresh_token, expires_at) values ('<access_token>', '<refresh_token>', '86400');
