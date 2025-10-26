SET SERVEROUTPUT ON; 

//FUNCION QUE RETORNA EL PROMEDIO DEL SUELDO DE 12 MESES
//PARA TRABAJADORES INDEPENDIENTES Y PENSIONADOS
CREATE OR REPLACE FUNCTION CALCULAR_RENTA(
    P_SUELDO_ACUMULADO NUMBER,
    P_TIPO_CLIENTE TIPO_CLIENTE.COD_TIPO_CLIENTE%TYPE
)RETURN NUMBER
AS
    V_CALCULO_RENTA NUMBER;
BEGIN
    IF(P_TIPO_CLIENTE = 1) THEN
        V_CALCULO_RENTA := (P_SUELDO_ACUMULADO/3);
    ELSIF (P_TIPO_CLIENTE =2) THEN
        V_CALCULO_RENTA := (P_SUELDO_ACUMULADO/24);
    ELSE
        V_CALCULO_RENTA := (P_SUELDO_ACUMULADO/12);
    END IF;
    RETURN V_CALCULO_RENTA;
EXCEPTION
    WHEN ZERO_DIVIDE THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE;
END;
/

--FUNCIONES QUE VALIDAN ASIGNAR CREDITOS SEGUN LA RENTA Y EL OFICIO
CREATE OR REPLACE FUNCTION VERIFICAR_CREDITO_HIPOTECARIO(
P_RENTA NUMBER,
P_PROFESION VARCHAR2)
RETURN BOOLEAN
AS 
    VERIFICACION BOOLEAN;
BEGIN
    IF (UPPER(p_profesion) = UPPER('Trabajadores dependientes') or UPPER(p_profesion) = UPPER('Trabajadores independientes')) AND (p_renta >= 1500000)  THEN
        VERIFICACION := TRUE;
    ELSE 
        VERIFICACION := FALSE;
    END IF;
    RETURN VERIFICACION;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
/

CREATE OR REPLACE FUNCTION VERIFICAR_CREDITO_CONSUMO(
P_RENTA NUMBER)
RETURN BOOLEAN
AS 
    VERIFICACION BOOLEAN;
BEGIN
    IF (p_renta >= 900000 )THEN
        VERIFICACION := TRUE;
    ELSE 
        VERIFICACION := FALSE;
    END IF;
    RETURN VERIFICACION;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
/

CREATE OR REPLACE FUNCTION VERIFICAR_CREDITO_AUTOMOTRIZ(
P_RENTA NUMBER,
P_PROFESION VARCHAR2
)
RETURN BOOLEAN
AS 
    VERIFICACION BOOLEAN;
BEGIN
    IF( UPPER(p_profesion) = UPPER('Trabajadores dependientes') or UPPER(p_profesion) = UPPER('Trabajadores independientes')) AND (p_renta >= 900000 ) THEN
        VERIFICACION := TRUE;
    ELSE 
        VERIFICACION := FALSE;
    END IF;
    RETURN VERIFICACION;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
/

CREATE OR REPLACE FUNCTION VERIFICAR_CREDITO_EMERGENCIA(
P_RENTA NUMBER,
P_PROFESION VARCHAR2
)
RETURN BOOLEAN
AS 
    VERIFICACION BOOLEAN;
BEGIN
    IF (UPPER(p_profesion) = UPPER('Trabajadores dependientes') or UPPER(p_profesion) = UPPER('Trabajadores independientes')) AND (p_renta >= 900000)  THEN
        VERIFICACION := TRUE;
    ELSIF UPPER(p_profesion) = UPPER('pensionado')AND (p_renta >= 150000) THEN
        VERIFICACION := TRUE;
    ELSE 
        VERIFICACION := FALSE;
    END IF;
    RETURN VERIFICACION;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
/     

CREATE OR REPLACE FUNCTION VERIFICAR_CREDITO_PAGO_ARANCEL(
P_RENTA NUMBER,
P_PROFESION VARCHAR2
)
RETURN BOOLEAN
AS 
    VERIFICACION BOOLEAN;
BEGIN
    IF( UPPER(p_profesion) = UPPER('Trabajadores dependientes') or UPPER(p_profesion) = UPPER('Trabajadores independientes')) AND (p_renta >= 900000 ) THEN
        VERIFICACION := TRUE;
    ELSE 
        VERIFICACION := FALSE;
    END IF;
    RETURN VERIFICACION;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
/ 

DECLARE
    V_ID_CLIENTE CLIENTE.NRO_CLIENTE%TYPE := &INGRESE_ID_CLIENTE ; --INGRESA POR PARAMETRO
    V_INGRESO_RENTA NUMBER:= &RENTA;
    V_PROMEDIO_RENTA NUMBER;
    v_algun_credito_aprobado BOOLEAN := FALSE;
    
    CURSOR CUR_CLIENTE IS
    SELECT C.nro_cliente AS "ID",
    C.PNOMBRE||' '|| C.SNOMBRE||' '||C.appaterno||' '||C.apmaterno AS "NOMBRE",
    tc.cod_tipo_cliente AS "TIPO_CLIENTE",
    tc.promedio_renta AS "TIPO_DE_CALCULO",
    tc.nombre_tipo_cliente as "OFICIO"
    FROM CLIENTE C
    JOIN TIPO_CLIENTE TC ON TC.COD_TIPO_CLIENTE = C.COD_TIPO_CLIENTE
    WHERE C.NRO_CLIENTE = V_ID_CLIENTE;
    
BEGIN
    BEGIN
        FOR I IN CUR_CLIENTE
        LOOP
            DBMS_OUTPUT.PUT_LINE('CLIENTE:'||I.NOMBRE);
            DBMS_OUTPUT.PUT_LINE('OFICIO:'||I.OFICIO);
            DBMS_OUTPUT.PUT_LINE('CALCULO EN BASE:'||I.TIPO_DE_CALCULO);
            
            v_promedio_renta := CALCULAR_RENTA(V_INGRESO_RENTA,I.TIPO_CLIENTE);
            DBMS_OUTPUT.PUT_LINE('EL PROMEDIO DE RENTA ES:'||round(v_promedio_renta));
            
            -- Llama a la función VERIFICAR_CREDITO_HIPOTECARIO
            IF VERIFICAR_CREDITO_HIPOTECARIO(v_promedio_renta, I.OFICIO) THEN
                DBMS_OUTPUT.PUT_LINE('Crédito Hipotecario: APROBADO.');
                v_algun_credito_aprobado := TRUE;
            END IF;

            -- Llama a la función VERIFICAR_CREDITO_CONSUMO
            IF VERIFICAR_CREDITO_CONSUMO(v_promedio_renta) THEN
                DBMS_OUTPUT.PUT_LINE('Crédito de Consumo: APROBADO.');
                v_algun_credito_aprobado := TRUE;
            END IF;

            -- Llama a la función VERIFICAR_CREDITO_AUTOMOTRIZ
            IF VERIFICAR_CREDITO_AUTOMOTRIZ(v_promedio_renta, I.OFICIO) THEN
                DBMS_OUTPUT.PUT_LINE('Crédito Automotriz: APROBADO.');
                v_algun_credito_aprobado := TRUE;
            END IF;
            
            -- Llama a la función VERIFICAR_CREDITO_EMERGENCIA
            IF VERIFICAR_CREDITO_EMERGENCIA(v_promedio_renta, I.OFICIO) THEN
                DBMS_OUTPUT.PUT_LINE('Crédito de Emergencia: APROBADO.');
                v_algun_credito_aprobado := TRUE;
            END IF;

            -- Llama a la función VERIFICAR_CREDITO_PAGO_ARANCEL
            IF VERIFICAR_CREDITO_PAGO_ARANCEL(v_promedio_renta, I.OFICIO) THEN
                DBMS_OUTPUT.PUT_LINE('Crédito Pago Arancel: APROBADO.');
                v_algun_credito_aprobado := TRUE;
            END IF;
            
            -- Verificación final: si la bandera nunca cambió a TRUE, no se aprobó nada.
            IF  v_algun_credito_aprobado= FALSE THEN
                DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
                DBMS_OUTPUT.PUT_LINE('No hay créditos disponibles para este cliente.');
            END IF;
        END LOOP;
        
        -- Si el cursor no devolvió ningún registro
        IF NOT CUR_CLIENTE%FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Error: No se encontró el cliente con ID: ' || V_ID_CLIENTE);
        END IF;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Error: No se encontraron datos para el cliente.');
        WHEN TOO_MANY_ROWS THEN
            DBMS_OUTPUT.PUT_LINE('Error: Se encontraron múltiples clientes con el mismo ID.');
        WHEN VALUE_ERROR THEN
            DBMS_OUTPUT.PUT_LINE('Error: Valor ingresado no válido.');
        WHEN ZERO_DIVIDE THEN
            DBMS_OUTPUT.PUT_LINE('Error: División por cero en el cálculo de renta.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
    END;
END;
/


CREATE TABLE MONTO_INGRESO(
    COD_MONTO_INGRESO NUMBER(5,0)PRIMARY KEY,
    INGRESO NUMBER(20),
    NRO_CLIENTE NUMBER(5,0),
    FOREIGN KEY(NRO_CLIENTE) REFERENCES CLIENTE(NRO_CLIENTE),
    UNIQUE(NRO_CLIENTE)
)


CREATE SEQUENCE SEQ_ID_MONTO_INGRESO
START WITH 1      
INCREMENT BY 1    
NOCACHE;

CREATE OR REPLACE TRIGGER TRG_SEQ_ID_MONTO_INGRESO
BEFORE INSERT ON MONTO_INGRESO

    FOR EACH ROW
        BEGIN 
            IF :NEW.COD_MONTO_INGRESO IS NULL THEN
                SELECT SEQ_ID_MONTO_INGRESO.NEXTVAL 
                INTO :NEW.COD_MONTO_INGRESO;
            END IF;
END;



