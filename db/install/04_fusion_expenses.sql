--------------------------------------------------------------------------------
-- 04_fusion_expenses.sql
-- Pull Expense Reports from Oracle Fusion Cloud Financials via its REST API and
-- stage them locally so an APEX interactive report can display them.
--
-- API: GET https://<host>/fscmRestApi/resources/11.13.18.05/expenseReports
-- Auth: HTTP Basic (the Fusion user id / password supplied at runtime).
--
-- Requirements on OCI Autonomous Database:
--   * APEX_WEB_SERVICE is available out of the box.
--   * An ACL / network egress to the Fusion host. On ADB grant it once:
--       BEGIN
--         DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
--           host => 'your-fusion-host.fa.ocs.oraclecloud.com',
--           ace  => xs$ace_type(privilege_list => xs$name_list('http'),
--                               principal_name => '<YOUR_SCHEMA>',
--                               principal_type => xs_acl.ptype_db));
--       END;
--       /
--     (Replace host and schema. APEX may also require a Web Credential / wallet
--      for TLS — see apex/README_fusion_expenses.md.)
--------------------------------------------------------------------------------

------------------------------------------------------------------- staging table
begin
  execute immediate 'drop table fusion_expense_reports cascade constraints';
exception when others then if sqlcode != -942 then raise; end if;
end;
/

create table fusion_expense_reports (
  expense_report_id    number
                         constraint fusion_exp_rep_pk primary key,
  report_number        varchar2(80 char),
  report_status        varchar2(80 char),
  status_code          varchar2(40 char),
  report_total         number(18,2),
  currency_code        varchar2(15 char),
  purpose              varchar2(4000 char),
  person_id            number,
  report_date          date,
  final_approval_date  date,
  fetched_on           timestamp default systimestamp not null,
  fetched_by           varchar2(255 char) default coalesce(sys_context('APEX$SESSION','APP_USER'), user) not null
);

create index fusion_exp_rep_status_i on fusion_expense_reports (report_status);

------------------------------------------------------------------- package spec
create or replace package fusion_expenses_pkg as

  -- Calls the Fusion expenseReports REST resource and MERGEs the results into
  -- FUSION_EXPENSE_REPORTS. Returns the number of reports loaded.
  --
  -- p_base_url   e.g. https://your-fusion-host.fa.ocs.oraclecloud.com
  --              (no trailing slash; the resource path is appended).
  -- p_username   Fusion user id   (supplied from the APEX page at runtime).
  -- p_password   Fusion password  (supplied from the APEX page at runtime).
  -- p_status     optional ExpenseReportStatus filter (e.g. 'PAID', 'PENDING MANAGER APPROVAL').
  -- p_max_rows   safety cap on how many reports to pull.
  function fetch_reports (
    p_base_url in varchar2,
    p_username in varchar2,
    p_password in varchar2,
    p_status   in varchar2 default null,
    p_max_rows in pls_integer default 500
  ) return pls_integer;

end fusion_expenses_pkg;
/

------------------------------------------------------------------- package body
create or replace package body fusion_expenses_pkg as

  c_resource constant varchar2(120) := '/fscmRestApi/resources/11.13.18.05/expenseReports';
  c_page     constant pls_integer   := 100;  -- Fusion default/typical page size

  -- Fusion returns dates as 'YYYY-MM-DD'; tolerate nulls/odd values.
  function to_date_safe (p_str in varchar2) return date is
  begin
    if p_str is null then return null; end if;
    return to_date(substr(p_str, 1, 10), 'YYYY-MM-DD');
  exception when others then
    return null;
  end to_date_safe;

  function fetch_reports (
    p_base_url in varchar2,
    p_username in varchar2,
    p_password in varchar2,
    p_status   in varchar2 default null,
    p_max_rows in pls_integer default 500
  ) return pls_integer is
    l_url       varchar2(1000);
    l_response  clob;
    l_offset    pls_integer := 0;
    l_count     pls_integer := 0;
    l_items     pls_integer;
    l_has_more  boolean := true;
  begin
    if p_base_url is null or p_username is null or p_password is null then
      raise_application_error(-20002, 'Base URL, username and password are all required.');
    end if;

    while l_has_more and l_count < p_max_rows loop
      -- Build the request URL with paging, only the data, and an optional filter.
      l_url := rtrim(p_base_url, '/') || c_resource
               || '?onlyData=true'
               || '&limit='  || c_page
               || '&offset=' || l_offset;

      if p_status is not null then
        l_url := l_url || '&q=' || apex_util.url_encode('ExpenseReportStatus=''' || p_status || '''');
      end if;

      l_response := apex_web_service.make_rest_request(
                      p_url         => l_url,
                      p_http_method => 'GET',
                      p_username    => p_username,
                      p_password    => p_password );

      if apex_web_service.g_status_code != 200 then
        raise_application_error(
          -20003,
          'Fusion API returned HTTP ' || apex_web_service.g_status_code ||
          '. Check the base URL, credentials, and that REST access is enabled.');
      end if;

      apex_json.parse(l_response);
      l_items := apex_json.get_count(p_path => 'items');

      if l_items is null or l_items = 0 then
        exit;
      end if;

      for i in 1 .. l_items loop
        merge into fusion_expense_reports t
        using (select apex_json.get_number (p_path => 'items[%d].ExpenseReportId',     p0 => i) as expense_report_id,
                      apex_json.get_varchar2(p_path => 'items[%d].ExpenseReportNumber', p0 => i) as report_number,
                      apex_json.get_varchar2(p_path => 'items[%d].ExpenseReportStatus', p0 => i) as report_status,
                      apex_json.get_varchar2(p_path => 'items[%d].ExpenseStatusCode',   p0 => i) as status_code,
                      apex_json.get_number  (p_path => 'items[%d].ExpenseReportTotal',  p0 => i) as report_total,
                      apex_json.get_varchar2(p_path => 'items[%d].ReimbursementCurrencyCode', p0 => i) as currency_code,
                      apex_json.get_varchar2(p_path => 'items[%d].Purpose',             p0 => i) as purpose,
                      apex_json.get_number  (p_path => 'items[%d].PersonId',            p0 => i) as person_id,
                      apex_json.get_varchar2(p_path => 'items[%d].ExpenseReportDate',   p0 => i) as report_date,
                      apex_json.get_varchar2(p_path => 'items[%d].FinalApprovalDate',   p0 => i) as final_approval_date
               from dual) s
        on (t.expense_report_id = s.expense_report_id)
        when matched then update set
              t.report_number       = s.report_number,
              t.report_status       = s.report_status,
              t.status_code         = s.status_code,
              t.report_total        = s.report_total,
              t.currency_code       = s.currency_code,
              t.purpose             = s.purpose,
              t.person_id           = s.person_id,
              t.report_date         = to_date_safe(s.report_date),
              t.final_approval_date = to_date_safe(s.final_approval_date),
              t.fetched_on          = systimestamp,
              t.fetched_by          = coalesce(sys_context('APEX$SESSION','APP_USER'), user)
        when not matched then insert (
              expense_report_id, report_number, report_status, status_code,
              report_total, currency_code, purpose, person_id,
              report_date, final_approval_date)
        values (
              s.expense_report_id, s.report_number, s.report_status, s.status_code,
              s.report_total, s.currency_code, s.purpose, s.person_id,
              to_date_safe(s.report_date), to_date_safe(s.final_approval_date));

        l_count := l_count + 1;
        exit when l_count >= p_max_rows;
      end loop;

      -- Page forward only if Fusion filled the page.
      l_has_more := (l_items = c_page);
      l_offset   := l_offset + c_page;
    end loop;

    commit;
    return l_count;
  end fetch_reports;

end fusion_expenses_pkg;
/
