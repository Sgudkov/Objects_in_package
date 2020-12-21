*&---------------------------------------------------------------------*
*& Include          ZMS_DEVREPORT_CI01
*&---------------------------------------------------------------------*

CLASS lcl_ms_report IMPLEMENTATION.

  METHOD fill_tadir.

    "Main query + methods
    SELECT td~*, tm~methodname AS method, tm~classname AS classname
      INTO CORRESPONDING FIELDS OF TABLE @mt_tadir
      FROM tadir AS td
      LEFT OUTER JOIN tmdir AS tm
        ON tm~classname = td~obj_name
      WHERE td~devclass = @p_pack
      AND td~delflag = @abap_false.
    IF sy-subrc <> 0.
      MESSAGE 'Current package is not defined' TYPE 'S' DISPLAY LIKE 'E'.
      mv_check = abap_true.
    ENDIF.

    LOOP AT mt_tadir ASSIGNING FIELD-SYMBOL(<ls_tadir>) WHERE method IS NOT INITIAL.
      <ls_tadir>-obj_name+30 = <ls_tadir>-method.
      <ls_tadir>-object = 'METH'.
    ENDLOOP.

    "Function moduls
    SELECT
        en~funcname  AS obj_name,
       'FUNC' AS object,
        mt~devclass
      FROM enlfdir AS en
      JOIN @mt_tadir AS mt
        ON mt~obj_name = en~area
      JOIN tfdir AS tf
        ON tf~funcname = en~funcname
      WHERE en~generated = @space
       APPENDING CORRESPONDING FIELDS OF TABLE @mt_tadir.

    "Function groups
    SELECT
        tf~pname  AS obj_name,
       'REPS' AS object,
        mt~devclass,
        'Report' AS name
      FROM enlfdir AS en
      JOIN @mt_tadir AS mt
        ON mt~obj_name = en~area
      JOIN tfdir AS tf
        ON tf~funcname = en~funcname
      WHERE en~generated = @space
       INTO TABLE @DATA(lt_reps).

    CHECK sy-subrc = 0.

    SORT lt_reps BY object obj_name.
    DELETE ADJACENT DUPLICATES FROM lt_reps COMPARING object obj_name.

    mt_tadir = CORRESPONDING #( BASE ( mt_tadir ) lt_reps ).

  ENDMETHOD.

  METHOD prepare_tabs.

    CONSTANTS:
      lc_meth TYPE string VALUE 'METH'.

    DATA lt_exc_tab TYPE TABLE OF tadir.

    lt_exc_tab = VALUE #( ( object = 'TABL' )
                          ( object = 'TTYP' )
                          ( object = 'DTEL' )
                          ( object = 'DOMA' ) ).

    LOOP AT mt_tadir ASSIGNING FIELD-SYMBOL(<ls_tadir>).

      IF <ls_tadir>-method IS INITIAL.
        DATA(lt_seu_objtxt) = VALUE typ_t_adwp_seu_objtxt( ( object = <ls_tadir>-object obj_name = <ls_tadir>-obj_name ) ).

        CALL FUNCTION 'RS_SHORTTEXT_GET'
          EXPORTING
            language = sy-langu
          TABLES
            obj_tab  = lt_seu_objtxt.
        <ls_tadir>-name = VALUE #( lt_seu_objtxt[ 1 ]-stext OPTIONAL ).

      ELSE.
        <ls_tadir>-object = lc_meth.
        <ls_tadir>-name = get_method_descr( <ls_tadir> ).
      ENDIF.
      IF line_exists( lt_exc_tab[ object = <ls_tadir>-object ] ).
        mt_struct = VALUE #( BASE mt_struct ( <ls_tadir> ) ).
      ELSE.
        mt_object = VALUE #( BASE mt_object ( <ls_tadir> ) ).
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD fill_tabs.

    DATA it_val TYPE STANDARD TABLE OF zwww_values.

    FIELD-SYMBOLS: <ls_val> LIKE LINE OF it_val.
    
    "Macros for fill table for unload MS doc.
    "Go to link in readme.txt for more information
    DEFINE set_line.
      APPEND INITIAL LINE TO it_val ASSIGNING <ls_val>.
      <ls_val>-var_name = &1.
      <ls_val>-var_num  = &2.
      <ls_val>-find_text = &3.
      <ls_val>-val_type = &4.
      <ls_val>-value = &5.
    END-OF-DEFINITION.

    me->fill_tadir( ).
    CHECK mv_check = abap_false.
    me->prepare_tabs( ).

    DATA(lt_req_tab) = get_req_table( ).

    " Fill header
    set_line '' 0 '[report_title]'  '' p_name.
    set_line '' 0 '[group_title]'   '' p_pack+6(3).
    set_line '' 0 '[package_title]' '' p_pack.


    SORT lt_req_tab BY trkorr.
    SORT mt_object  BY object.
    SORT mt_struct  BY object.

    " Fill transport's requests table
    LOOP AT lt_req_tab ASSIGNING FIELD-SYMBOL(<ls_line>).
      DATA(lv_tabix_req) = sy-tabix.
      set_line 'request_table' lv_tabix_req '[num]'             '' lv_tabix_req.
      set_line 'request_table' lv_tabix_req '[req_num]'         '' <ls_line>-trkorr.
      set_line 'request_table' lv_tabix_req '[sap_id]'          '' <ls_line>-trkorr(3).
      set_line 'request_table' lv_tabix_req '[owner]'           '' <ls_line>-as4user.
      set_line 'request_table' lv_tabix_req '[owner_name]'      '' <ls_line>-as4user_text.
      set_line 'request_table' lv_tabix_req '[req_description]' '' <ls_line>-as4text.
    ENDLOOP.

    " Fill classes, objects etc
    LOOP AT mt_object ASSIGNING FIELD-SYMBOL(<ls_program>).
      DATA(lv_tabix) = sy-tabix.
      DATA(lv_objname) = COND #(
        WHEN <ls_program>-method IS INITIAL THEN <ls_program>-obj_name
        ELSE <ls_program>-classname && '=>' && <ls_program>-method
      ).
      set_line 'program_object_t' lv_tabix '[num]'         '' lv_tabix.
      set_line 'program_object_t' lv_tabix '[object_type]' '' <ls_program>-object.
      set_line 'program_object_t' lv_tabix '[name_obj]'    '' lv_objname.
      set_line 'program_object_t' lv_tabix '[package]'     '' <ls_program>-devclass.
      set_line 'program_object_t' lv_tabix '[status]'      '' 'NEW'.
      set_line 'program_object_t' lv_tabix '[description]' '' <ls_program>-name.
    ENDLOOP.

    " Fill data elemetns, table types etc
    LOOP AT mt_struct ASSIGNING FIELD-SYMBOL(<ls_struct>).
      DATA(lv_tabix_str) = sy-tabix.
      set_line 'tables_object_t' lv_tabix_str '[num]'         '' lv_tabix_str.
      set_line 'tables_object_t' lv_tabix_str '[object_type]' '' <ls_struct>-object.
      set_line 'tables_object_t' lv_tabix_str '[name_obj]'    '' <ls_struct>-obj_name.
      set_line 'tables_object_t' lv_tabix_str '[package]'     '' <ls_struct>-devclass.
      set_line 'tables_object_t' lv_tabix_str '[status]'      '' 'NEW'.
      set_line 'tables_object_t' lv_tabix_str '[description]' '' <ls_struct>-name.
    ENDLOOP.

    IF mt_struct IS INITIAL.
      set_line 'tables_object_t' 1 '[num]'         '' abap_false.
      set_line 'tables_object_t' 1 '[object_type]' '' abap_false.
      set_line 'tables_object_t' 1 '[name_obj]'    '' abap_false.
      set_line 'tables_object_t' 1 '[package]'     '' abap_false.
      set_line 'tables_object_t' 1 '[status]'      '' abap_false.
      set_line 'tables_object_t' 1 '[description]' '' abap_false.
    ENDIF.
    APPEND LINES OF it_val TO rt_values.

  ENDMETHOD.

  METHOD get_req_table.

    CONSTANTS:
      lc_blank TYPE i VALUE 1.

    DATA lt_data TYPE TABLE OF mty_s_data.

    SELECT DISTINCT
         e070_self~trkorr, e070_self~trfunction, e070_self~as4user,
         e070_self~trstatus, et~as4text, concat_with_space( ad~name_last,ad~name_first,@lc_blank ) AS as4user_text
       FROM e070
       JOIN e070 AS e070_self
         ON e070_self~trkorr = e070~strkorr
       JOIN e071
         ON e071~trkorr = e070~trkorr
       JOIN @mt_tadir AS obj
         ON obj~object = e071~object
        AND obj~obj_name = e071~obj_name
       JOIN e07t AS et
         ON et~trkorr = e070~trkorr
       JOIN usr21 AS us
         ON us~bname = e070~as4user
       JOIN adrp AS ad
         ON ad~persnumber = us~persnumber
       INTO CORRESPONDING FIELDS OF TABLE @lt_data[].

    IF sy-subrc = 0.

      "Transport requests from another packages
      SELECT DISTINCT e071~trkorr
        FROM e071
        JOIN tadir ON tadir~object = e071~object
                  AND tadir~obj_name = e071~obj_name
        FOR ALL ENTRIES IN @lt_data
        WHERE e071~trkorr = @lt_data-trkorr
         AND tadir~devclass <> @p_pack
        INTO TABLE @DATA(lt_complex_reqs).
      IF sy-subrc = 0.
        SORT lt_complex_reqs STABLE BY trkorr ASCENDING.
      ENDIF.

    ENDIF.

    DELETE lt_data[] WHERE trfunction <> 'K'.

    SORT lt_data BY trkorr ASCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_data COMPARING trkorr.

    APPEND LINES OF lt_data TO rt_req_tab.

  ENDMETHOD.

  METHOD get_method_descr.

    TYPES BEGIN OF lty_class.
    TYPES class_name TYPE string.
    TYPES method_name TYPE string.
    TYPES END OF   lty_class.

    DATA ls_class TYPE lty_class.

    DATA(lv_method) = is_tadir-method.

    SPLIT lv_method AT '~' INTO ls_class-class_name ls_class-method_name.
    IF ls_class-method_name IS INITIAL.
      SELECT SINGLE descript FROM seocompotx INTO @rv_descr
            WHERE clsname = @is_tadir-obj_name  AND
                  cmpname = @is_tadir-method AND
                  langu   = @sy-langu.
    ELSE.
      SELECT SINGLE descript FROM seocompotx INTO @rv_descr
            WHERE clsname = @ls_class-class_name  AND
                  cmpname = @ls_class-method_name AND
                  langu   = 'EN'.

    ENDIF.

  ENDMETHOD.

  METHOD upload_report.

    DATA(lt_values) = fill_tabs( ).

    CALL FUNCTION 'ZWWW_OPENFORM'
      EXPORTING
        form_name   = mc_formname
        protect     = abap_false
        optimize    = 9999
        file_name   = p_name
      TABLES
        it_values   = lt_values
      EXCEPTIONS
        printcancel = 1
        OTHERS      = 2.
    IF sy-subrc <> 0.
      WRITE 'Oops, something going wrong!'.
    ENDIF.
  ENDMETHOD.

  METHOD make_report.
    upload_report(  ).
  ENDMETHOD.


ENDCLASS.
