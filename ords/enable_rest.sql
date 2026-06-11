--------------------------------------------------------------------------------
-- enable_rest.sql
-- Optional: expose the products table as an auto-REST resource through ORDS.
-- Run as the application schema owner. On OCI Autonomous Database, ORDS is
-- already provisioned, so this is all that is required.
--
-- After running, the endpoints live under:
--   https://<your-adb-host>/ords/<schema>/products/
--------------------------------------------------------------------------------

begin
  ords.enable_schema (
    p_enabled             => true,
    p_schema              => sys_context('userenv','current_schema'),
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => lower(sys_context('userenv','current_schema')),
    p_auto_rest_auth      => true   -- require authentication for the auto-REST endpoints
  );

  ords.enable_object (
    p_enabled        => true,
    p_schema         => sys_context('userenv','current_schema'),
    p_object         => 'PRODUCTS',
    p_object_type    => 'TABLE',
    p_object_alias   => 'products',
    p_auto_rest_auth => true
  );

  commit;
end;
/
