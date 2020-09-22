*&---------------------------------------------------------------------*
*& Report ZMS_DEVREPORT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zms_devreport.

SELECTION-SCREEN BEGIN OF BLOCK b1.
PARAMETERS: p_pack TYPE tadir-devclass OBLIGATORY,
            p_name TYPE rlgrap-filename OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

INCLUDE zms_devreport_cd01.
INCLUDE zms_devreport_ci01.

START-OF-SELECTION.

  NEW lcl_ms_report( )->make_report( ).
