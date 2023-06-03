create table codes
(
    code_id            bytea not null
        constraint codes_pk
            primary key,
    code_length        integer default 1,
    code_status        integer default 1,
    code_measure_unit  varchar,
    code_math_multiple double precision
);

create table code_names
  (
      code_key             integer not null,
      code_name            varchar not null,
      country_language_iso varchar default 'en-US',
      code_name_status     integer default 1
  );
comment on table code_names is 'codes (avl) names by country/language ISO';
comment on column code_names.code_key is 'codes->codes_pk(foreign code_id)';
comment on column code_names.code_name_status is '1 activated (...)';
create unique index code_names_code_name_uindex
    on code_names (code_name);
