--
-- CREATE package spec tinitiate.commons_logger
--
CREATE OR REPLACE package tinitiate.commons_logger
as

-- ---------------------------------------------------------------------------- 
-- Name: commons_logger
-- Desc: Common Logger utility
--
-- Name         Date            Change Notes
-- ----------------------------------------------------------------------------
-- Venkata B    Dec 12, 2016    Initial version
--
-- ----------------------------------------------------------------------------

    -- Collection of the Pkg Objects
    type vlog_obj is table of commons_log_config%rowtype index by binary_integer;
    tab_vlog vlog_obj;

    procedure AddComponent( p_owner                 in varchar2
                           ,p_module_name           in varchar2
                           ,p_component_name        in varchar2
                           ,p_log_info_verbose_flg  in char
                           ,p_log_info_terse_flg    in char);


    procedure EnableVerboseAudLog( p_owner           in varchar2 
                                  ,p_module_name     in varchar2
                                  ,p_component_name  in varchar2);


    procedure DisableVerboseAudLog( p_owner           in varchar2
                                   ,p_module_name     in varchar2
                                   ,p_component_name  in varchar2);


    procedure EnableTerseAudLog( p_owner           in varchar2
                                ,p_module_name     in varchar2
                                ,p_component_name  in varchar2);


    procedure DisableTerseAudLog( p_owner           in varchar2
                                 ,p_module_name     in varchar2
                                 ,p_component_name  in varchar2);


    procedure vLog( p_log_message  in varchar2
                   ,p_job_number   in varchar2 default null
                   ,p_calling_unit in varchar2 default UTL_Call_Stack.Concatenate_Subprogram(UTL_Call_Stack.Subprogram(1)));


    procedure Log( p_log_message   in varchar2
                   ,p_job_number   in varchar2 default null
                   ,p_calling_unit in varchar2 default UTL_Call_Stack.Concatenate_Subprogram(UTL_Call_Stack.Subprogram(1)));


    procedure eLog( p_error_message in varchar2 default null
                   ,p_job_number    in varchar2 default null
                   ,p_sqlerr        in varchar2 default SQLERRM
                   ,p_calling_unit  in varchar2 default UTL_Call_Stack.Concatenate_Subprogram(UTL_Call_Stack.Subprogram(1)));

    procedure commons_init( p_owner       in varchar2
                           ,p_module_name in varchar2);

end commons_logger;
/


--
-- create package body tinitiate.commons_logger
--
CREATE OR REPLACE package body tinitiate.commons_logger
as
-- ---------------------------------------------------------------------------- 
-- Name: commons_logger
-- Desc: Common Logger utility
--
-- Name         Date            Change Notes
-- ----------------------------------------------------------------------------
-- Venkata B    Dec 12, 2016    Initial version
--
-- ----------------------------------------------------------------------------

    -- Call this in the PKG initialize section at all times
    procedure commons_init( p_owner       in varchar2
                           ,p_module_name in varchar2)
    as
    begin

        select *
        bulk collect into  tab_vlog
        from   commons_log_config
        where  owner = p_owner
        and    upper(module_name) = upper(p_module_name)
        and    upper(log_info_verbose_flg) = 'Y';

    end commons_init;
   

    procedure ExtractComponentModule( p_calling_unit   in     varchar2
                                     ,p_module_name       out varchar2
                                     ,p_component_name    out varchar2)
    as
    
    begin

        if instr(p_calling_unit, '.', 1) = 0
        then
            p_module_name := p_calling_unit;
            p_component_name := p_calling_unit;
        else
            p_module_name := trim(substr(p_calling_unit,1,instr(p_calling_unit,'.',1)-1));
            p_component_name := trim(substr(p_calling_unit,instr(p_calling_unit,'.',1)+1,length(p_calling_unit)));     
        end if;
    
    end ExtractComponentModule;
        
                                 
    procedure AddComponent( p_owner                 in varchar2
                           ,p_module_name           in varchar2
                           ,p_component_name        in varchar2
                           ,p_log_info_verbose_flg  in char
                           ,p_log_info_terse_flg    in char)
    as
    begin
        insert into commons_log_config ( owner
                                        ,module_name
                                        ,component_name
                                        ,log_info_verbose_flg
                                        ,log_info_terse_flg)
        values ( p_owner
                ,p_module_name
                ,p_component_name
                ,p_log_info_verbose_flg
                ,p_log_info_terse_flg);

        commit;

    end AddComponent;


    procedure EnableVerboseAudLog( p_owner           in varchar2 
                                  ,p_module_name     in varchar2
                                  ,p_component_name  in varchar2)
    as
    begin

        update commons_log_config
        set    log_info_verbose_flg = 'Y'
        where  upper(owner)          = upper(p_owner)
        and    upper(module_name)    = upper(p_module_name)
        and    upper(component_name) = upper(p_component_name);
        
        commit;

    end EnableVerboseAudLog;


    procedure DisableVerboseAudLog( p_owner           in varchar2
                                   ,p_module_name     in varchar2
                                   ,p_component_name  in varchar2)
    as
    begin
        update commons_log_config
        set    log_info_verbose_flg = 'N'
        where  upper(owner)          = upper(p_owner)
        and    upper(module_name)    = upper(p_module_name)
        and    upper(component_name) = upper(p_component_name);

        commit;

    end DisableVerboseAudLog;

    
    procedure EnableTerseAudLog( p_owner           in varchar2
                                ,p_module_name     in varchar2
                                ,p_component_name  in varchar2)
    as
    begin

        update commons_log_config
        set    log_info_terse_flg = 'Y'
        where  upper(owner)          = upper(p_owner)
        and    upper(module_name)    = upper(p_module_name)
        and    upper(component_name) = upper(p_component_name);

        commit;

    end EnableTerseAudLog;


    procedure DisableTerseAudLog( p_owner           in varchar2
                                 ,p_module_name     in varchar2
                                 ,p_component_name  in varchar2)
    as
    begin
    
        update commons_log_config
        set    log_info_terse_flg = 'N'
        where  upper(owner)          = upper(p_owner)
        and    upper(module_name)    = upper(p_module_name)
        and    upper(component_name) = upper(p_component_name);
        
        commit;
        
    end DisableTerseAudLog;


    procedure vLog( p_log_message  in varchar2
                   ,p_job_number   in varchar2 default null
                   ,p_calling_unit in varchar2 default UTL_Call_Stack.Concatenate_Subprogram(UTL_Call_Stack.Subprogram(1)))
    as
        PRAGMA AUTONOMOUS_TRANSACTION;
        l_ins            int := 0;
        l_module_name    varchar2(30);
        l_component_name varchar2(30);
    begin
    --
        ExtractComponentModule(p_calling_unit, l_module_name, l_component_name);

        begin
            for i in (select upper(component_name) component_name
                      from   table(tab_vlog)
                      where  upper(component_name) = upper(trim(l_component_name)))
            loop
                -- dbms_output.put_line(i.component_name || upper(gComponentName));
                l_ins := 1;
            end loop;

        exception
        when others then
            l_ins := 0;
        end;

        if l_ins = 1
        then  
            insert into commons_audit_log ( component_name
                                           ,module_name
                                           ,job_number
                                           ,log_date
                                           ,log_datetime_local
                                           ,log_datetime_gmt
                                           ,username
                                           ,osuser
                                           ,audithost
                                           ,audit_message)
            values ( l_component_name
                    ,l_module_name
                    ,p_job_number
                    ,trunc(sysdate)
                    ,sysdate
                    ,CAST(systimestamp AT TIME ZONE 'GMT' AS DATE)
                    ,sys_context('USERENV','SESSION_USER')
                    ,sys_context('USERENV','OS_USER')
                    ,sys_context('USERENV','HOST')
                    ,p_log_message);

        end if;

        commit;

    end vlog;


    procedure Log( p_log_message  in varchar2
                  ,p_job_number   in varchar2 default null
                  ,p_calling_unit in varchar2 default UTL_Call_Stack.Concatenate_Subprogram(UTL_Call_Stack.Subprogram(1)))
    as
        PRAGMA AUTONOMOUS_TRANSACTION;
        l_module_name    varchar2(30);
        l_component_name varchar2(30);
    begin
    --
        ExtractComponentModule(p_calling_unit, l_module_name, l_component_name);

        insert into commons_audit_log ( component_name
                                       ,module_name
                                       ,job_number
                                       ,log_date
                                       ,log_datetime_local
                                       ,log_datetime_gmt
                                       ,username
                                       ,osuser
                                       ,audithost
                                       ,audit_message)
        values ( l_component_name
                ,l_module_name
                ,p_job_number
                ,trunc(sysdate)
                ,sysdate
                ,CAST(systimestamp AT TIME ZONE 'GMT' AS DATE)
                ,sys_context('USERENV','SESSION_USER')
                ,sys_context('USERENV','OS_USER')
                ,sys_context('USERENV','HOST')
                ,p_log_message);
        --
        commit;
    --
    end log;


    procedure eLog( p_error_message in varchar2 default null
                   ,p_job_number    in varchar2 default null
                   ,p_sqlerr        in varchar2 default SQLERRM
                   ,p_calling_unit  in varchar2 default UTL_Call_Stack.Concatenate_Subprogram(UTL_Call_Stack.Subprogram(1)))
    as
        PRAGMA AUTONOMOUS_TRANSACTION;
        l_module_name    varchar2(30);
        l_component_name varchar2(30);
        l_error_message  varchar2(4000):= substr(p_error_message||p_sqlerr,1,3999);  
        
    begin
    --
        ExtractComponentModule(p_calling_unit, l_module_name, l_component_name);
        
        insert into commons_error_log ( component_name
                                       ,module_name
                                       ,job_number
                                       ,log_date
                                       ,log_datetime_local
                                       ,log_datetime_gmt
                                       ,username
                                       ,osuser
                                       ,audithost
                                       ,error_message
                                       ,ora_error_message)
        values ( l_component_name
                ,l_module_name
                ,p_job_number
                ,trunc(sysdate)
                ,sysdate
                ,cast(systimestamp at time zone 'GMT' as date)
                ,sys_context('USERENV','SESSION_USER')
                ,sys_context('USERENV','OS_USER')
                ,sys_context('USERENV','HOST')
                ,l_error_message
                ,dbms_utility.format_error_backtrace());

        commit;

    end elog;

end commons_logger;
/
