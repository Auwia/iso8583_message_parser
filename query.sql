SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
  v_blob      BLOB;
  v_raw       RAW(7104);
  v_len       NUMBER;
  v_cursor    INTEGER := 1;
  v_mti       VARCHAR2(8);
  v_bitmap    VARCHAR2(256);

  -- === FUNZIONI UTILI ===
  FUNCTION extract_bytes(p_raw RAW, p_start IN OUT INTEGER, p_len INTEGER) RETURN RAW IS
    v_part RAW(2000);
  BEGIN
    v_part := SUBSTR(p_raw, p_start, p_len);
    p_start := p_start + p_len;
    RETURN v_part;
  END;

  FUNCTION raw_to_str(p_raw RAW) RETURN VARCHAR2 IS
  BEGIN
    RETURN UTL_RAW.CAST_TO_VARCHAR2(p_raw);
  END;

  FUNCTION raw_to_hex(p_raw RAW) RETURN VARCHAR2 IS
  BEGIN
    RETURN RAWTOHEX(p_raw);
  END;

  FUNCTION hex_to_bin(p_hex VARCHAR2) RETURN VARCHAR2 IS
    v_bin VARCHAR2(512);
  BEGIN
    FOR i IN 1 .. LENGTH(p_hex) LOOP
      v_bin := v_bin || LPAD(TO_CHAR(TO_NUMBER(SUBSTR(p_hex, i, 1), 'X')), 4, '0');
    END LOOP;
    RETURN v_bin;
  END;

  FUNCTION extract_llvar(p_raw RAW, p_cursor IN OUT INTEGER) RETURN VARCHAR2 IS
    v_len_raw RAW(1);
    v_len_num INTEGER;
    v_data_raw RAW(2000);
  BEGIN
    v_len_raw := extract_bytes(p_raw, p_cursor, 1);
    v_len_num := TO_NUMBER(UTL_RAW.CAST_TO_VARCHAR2(v_len_raw));
    v_data_raw := extract_bytes(p_raw, p_cursor, v_len_num);
    RETURN UTL_RAW.CAST_TO_VARCHAR2(v_data_raw);
  END;

  FUNCTION extract_lllvar(p_raw RAW, p_cursor IN OUT INTEGER) RETURN VARCHAR2 IS
    v_len_raw RAW(2);
    v_len_num INTEGER;
    v_data_raw RAW(2000);
  BEGIN
    v_len_raw := extract_bytes(p_raw, p_cursor, 2);
    v_len_num := TO_NUMBER(UTL_RAW.CAST_TO_VARCHAR2(v_len_raw));
    v_data_raw := extract_bytes(p_raw, p_cursor, v_len_num);
    RETURN UTL_RAW.CAST_TO_VARCHAR2(v_data_raw);
  END;

  PROCEDURE print_line(p_label VARCHAR2, p_value VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(p_label || ': ' || p_value);
  END;

  -- === PROCEDURA CAMPO ===
  PROCEDURE decode_field(p_num INTEGER, p_type VARCHAR2, p_len INTEGER, p_raw RAW, p_cursor IN OUT INTEGER) IS
    v_val VARCHAR2(4000);
  BEGIN
    IF p_type = 'N' OR p_type = 'AN' OR p_type = 'ANS' THEN
      v_val := raw_to_str(extract_bytes(p_raw, p_cursor, p_len));
    ELSIF p_type = 'B' THEN
      v_val := raw_to_hex(extract_bytes(p_raw, p_cursor, p_len));
    ELSIF p_type = 'LLVAR' THEN
      v_val := extract_llvar(p_raw, p_cursor);
    ELSIF p_type = 'LLLVAR' THEN
      v_val := extract_lllvar(p_raw, p_cursor);
    ELSE
      v_val := '[Tipo sconosciuto]';
    END IF;

    print_line('Campo ' || p_num, v_val);
  END;

  -- === DIZIONARIO CAMPI ISO ===
  TYPE t_field_def IS RECORD (num INTEGER, tipo VARCHAR2(10), len INTEGER);
  TYPE t_field_array IS TABLE OF t_field_def INDEX BY BINARY_INTEGER;
  v_fields t_field_array;

BEGIN
  -- === INIZIALIZZA DIZIONARIO CAMPI ISO ===
  v_fields(2)  := t_field_def(2,  'LLVAR', 19);
  v_fields(3)  := t_field_def(3,  'N', 6);
  v_fields(4)  := t_field_def(4,  'N', 12);
  v_fields(5)  := t_field_def(5,  'N', 12);
  v_fields(6)  := t_field_def(6,  'N', 12);
  v_fields(7)  := t_field_def(7,  'N', 10);
  v_fields(8)  := t_field_def(8,  'N', 8);
  v_fields(9)  := t_field_def(9,  'N', 8);
  v_fields(10) := t_field_def(10, 'N', 8);
  v_fields(11) := t_field_def(11, 'N', 6);
  v_fields(12) := t_field_def(12, 'N', 6);
  v_fields(13) := t_field_def(13, 'N', 4);
  v_fields(14) := t_field_def(14, 'N', 4);
  v_fields(15) := t_field_def(15, 'N', 4);
  v_fields(16) := t_field_def(16, 'N', 4);
  v_fields(18) := t_field_def(18, 'N', 4);
  v_fields(19) := t_field_def(19, 'N', 3);
  v_fields(22) := t_field_def(22, 'N', 3);
  v_fields(23) := t_field_def(23, 'N', 3);
  v_fields(25) := t_field_def(25, 'N', 2);
  v_fields(26) := t_field_def(26, 'N', 2);
  v_fields(28) := t_field_def(28, 'N', 9);
  v_fields(30) := t_field_def(30, 'N', 9);
  v_fields(32) := t_field_def(32, 'LLVAR', 11);
  v_fields(33) := t_field_def(33, 'LLVAR', 11);
  v_fields(35) := t_field_def(35, 'LLVAR', 37);
  v_fields(37) := t_field_def(37, 'AN', 12);
  v_fields(38) := t_field_def(38, 'AN', 6);
  v_fields(39) := t_field_def(39, 'AN', 2);
  v_fields(41) := t_field_def(41, 'ANS', 8);
  v_fields(42) := t_field_def(42, 'ANS', 15);
  v_fields(43) := t_field_def(43, 'ANS', 40);
  v_fields(44) := t_field_def(44, 'LLVAR', 25);
  v_fields(45) := t_field_def(45, 'LLVAR', 76);
  v_fields(48) := t_field_def(48, 'LLLVAR', 999);
  v_fields(49) := t_field_def(49, 'AN', 3);
  v_fields(52) := t_field_def(52, 'B', 8);
  v_fields(53) := t_field_def(53, 'N', 16);
  v_fields(54) := t_field_def(54, 'LLLVAR', 120);
  v_fields(55) := t_field_def(55, 'LLLVAR', 255);
  v_fields(60) := t_field_def(60, 'LLLVAR', 999);
  v_fields(61) := t_field_def(61, 'LLLVAR', 999);
  v_fields(62) := t_field_def(62, 'LLLVAR', 999);
  v_fields(63) := t_field_def(63, 'LLLVAR', 999);
  v_fields(64) := t_field_def(64, 'B', 8);

  -- === ESTRAI BLOB ===
  SELECT tuo_blob_campo, raw_len INTO v_blob, v_len
  FROM tua_tabella
  WHERE condizione
  AND ROWNUM = 1;

  v_raw := DBMS_LOB.SUBSTR(v_blob, v_len, 1);

  -- === SKIP HEADER (TPDU + ISO) ===
  v_cursor := v_cursor + 11;

  -- === MTI ===
  v_mti := raw_to_hex(extract_bytes(v_raw, v_cursor, 2));
  DBMS_OUTPUT.PUT_LINE('MTI: ' || v_mti);

  -- === BITMAP ===
  v_bitmap := raw_to_hex(extract_bytes(v_raw, v_cursor, 8));
  IF SUBSTR(v_bitmap, 1, 1) IN ('8','9','A','B','C','D','E','F') THEN
    v_bitmap := v_bitmap || raw_to_hex(extract_bytes(v_raw, v_cursor, 8)); -- secondary bitmap
  END IF;

  DBMS_OUTPUT.PUT_LINE('Bitmap HEX: ' || v_bitmap);
  DBMS_OUTPUT.PUT_LINE('--- Campi ---');

  -- === DECODE FIELDS ===
  DECLARE
    v_bin VARCHAR2(256) := hex_to_bin(v_bitmap);
  BEGIN
    FOR i IN 2 .. LENGTH(v_bin) LOOP
      IF SUBSTR(v_bin, i, 1) = '1' AND v_fields.EXISTS(i) THEN
        decode_field(i, v_fields(i).tipo, v_fields(i).len, v_raw, v_cursor);
      END IF;
    END LOOP;
  END;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Errore: ' || SQLERRM);
END;
