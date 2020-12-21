*&---------------------------------------------------------------------*
*& Include          ZMS_DEVREPORT_CD01
*&---------------------------------------------------------------------*

CLASS lcl_ms_report DEFINITION.

  PUBLIC SECTION.

    METHODS:
      make_report.

  PRIVATE SECTION.

    TYPES BEGIN OF mty_s_tadir.
    TYPES devclass TYPE tadir-devclass.
    TYPES method TYPE tmdir-methodname.
    types classname TYPE tmdir-classname.
    TYPES object TYPE trobjtype.
    TYPES obj_name TYPE char120.
    TYPES name TYPE string.
    TYPES END OF   mty_s_tadir.

    TYPES:
      BEGIN OF mty_s_data,
        complex         TYPE flag,
        trkorr          TYPE e070-trkorr,
        as4text         TYPE as4text,
        as4user         TYPE e070-as4user,
        as4user_text    TYPE dd07v-ddtext,
        trfunction      TYPE e070-trfunction,
        trfunction_text TYPE dd07v-ddtext,
        trstatus        TYPE e070-trstatus,
        trstatus_text   TYPE dd07v-ddtext,
      END OF mty_s_data,


      mt_t_data TYPE STANDARD TABLE OF mty_s_data WITH DEFAULT KEY,
      mt_t_val  TYPE STANDARD TABLE OF zwww_values WITH DEFAULT KEY.

    CONSTANTS:
      mc_formname TYPE w3objid VALUE 'ZREPORT_DEV'.

    DATA:
      mt_tadir  TYPE TABLE OF mty_s_tadir,
      mt_struct TYPE TABLE OF mty_s_tadir,
      mt_object TYPE TABLE OF mty_s_tadir,
      mv_check  TYPE boolean.

    METHODS:
      fill_tadir RAISING cx_static_check,
      prepare_tabs,
      get_method_descr
        IMPORTING
                  is_tadir        TYPE mty_s_tadir
        RETURNING VALUE(rv_descr) TYPE string,
      get_req_table RETURNING VALUE(rt_req_tab) TYPE mt_t_data,
      fill_tabs RETURNING VALUE(rt_values) TYPE mt_t_val,
      upload_report .



ENDCLASS.
