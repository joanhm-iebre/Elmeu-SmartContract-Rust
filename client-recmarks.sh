#!/bin/bash

CONTRACT="erd1qqqqqqqqqqqqqpgqu4rz3zpzhlattwzqgazlk6zttnrttj9cgdyqjgqxue"   # Cambia por la dirección real del SC
PEM="./walletjhm.pem"      # Cambia por la ruta a tu wallet
PROXY="https://devnet-api.multiversx.com"

# Función para convertir hex a decimal (maneja números grandes)
hex_to_decimal() {
  local hex_value=$1
  if [[ $hex_value == "0x"* ]]; then
    hex_value=${hex_value#0x}
  fi
  if [[ -z "$hex_value" || "$hex_value" == "00" || "$hex_value" == "" ]]; then
    echo "0"
  else
    # Usar python para manejar números grandes
    python3 -c "print(int('$hex_value', 16))" 2>/dev/null || echo "0"
  fi
}

# Función para convertir timestamp a fecha formato dd/MM/yy hh:mm:ss
timestamp_to_date() {
  local timestamp=$1
  if [[ $timestamp -eq 0 ]]; then
    echo "No definido"
  else
    # Intentar con sintaxis de macOS/BSD primero, luego con Linux
    date -r "$timestamp" "+%d/%m/%y %H:%M:%S" 2>/dev/null || \
    date -d "@$timestamp" "+%d/%m/%y %H:%M:%S" 2>/dev/null || \
    echo "Fecha inválida"
  fi
}


get_deadline() {
  echo "Consultant data límit..."
  result=$(mxpy contract query $CONTRACT \
    --function getDeadline \
    --proxy $PROXY 2>/dev/null)
  
  if [[ $? -eq 0 ]]; then
    # Extraer el valor hexadecimal de la respuesta (formato: ["hex_value"])
    hex_deadline=$(echo "$result" | grep -o '"[^"]*"' | head -1 | tr -d '"')
    if [[ -n "$hex_deadline" && "$hex_deadline" != "" ]]; then
      decimal_deadline=$(hex_to_decimal "$hex_deadline")
      date_deadline=$(timestamp_to_date "$decimal_deadline")
      echo "Data límit límit: $date_deadline (timestamp: $decimal_deadline)"
    else
      echo "No s'ha pogut parsejar la data límit"
      echo "Resposta raw: $result"
    fi
  else
    echo "Error al consultar la data límit"
  fi
}


# =======================================================================
# FUNCIÓ AUXILIAR: Converteix una cadena hexadecimal a text llegible
# =======================================================================
hex_to_string() {
    # La comanda 'xxd -p -r' llegeix una cadena hexadecimal i la converteix
    # a la seva representació ASCII (text).
    echo "$1" | xxd -p -r
}


# =======================================================================
# FUNCIÓ getmarks: Mostra les notes. Amb 0 les mostra totes, 
# amb 1 només mostra la del registre q coincideix amb DNI i Codicle
# =======================================================================
getMarks() {
    local mode=$1 # Capturem el paràmetre de mode (0 o 1)
    local all_records_text=""
    
    echo "Consultant registres de notes des del contracte..."

    # 1. Crida la view function
    result=$(mxpy contract query $CONTRACT \
        --function getMarkStudent \
        --proxy $PROXY \
        2>/dev/null) 

    if [[ $? -eq 0 ]]; then
        hex_data=$(echo "$result" | grep -o '"[^"]*"' | head -1 | tr -d '"')
        
        if [[ -n "$hex_data" && "$hex_data" != "" ]]; then
            
            if [ "$hex_data" == "00" ]; then
                echo "➡️ Encara no hi ha cap nota registrada."
                return 0
            fi

            # Descodificació de l'Hexadecimal a text llegible (la llista)
            all_records_text=$(hex_to_string "$hex_data")
            
        else
            echo "No s'ha pogut parsejar la resposta HEX. Resposta raw: $result"
            return 1
        fi
    else
        echo "Error al consultar la funció getMarkStudent. Codi de sortida: $?"
        return 1
    fi
    
    # ======================================================
    # LÒGICA CONDICIONAL BASADA EN EL PARÀMETRE 'mode'
    # ======================================================
    
    if [ "$mode" -eq 0 ]; then
        # ---------------------------------------------
        # MODE 0: Mostrar Tots els Registres Formats
        # ---------------------------------------------
        echo "==========================================="
        echo " Tots els Registres de notes (DNI-Cicle-Nota):"
        echo "==========================================="
        
        # Format: DNI-Cicle-Nota;DNI-Cicle-Nota
        IFS=';' read -ra records <<< "$all_records_text"
        
        for record in "${records[@]}"; do
            # S'assegura que no es processin cadenes buides si hi ha dobles ';;'
            if [[ -n "$record" ]]; then 
                # Reemplaça el '-' per un ': ' per a una millor visualització
                echo " - ${record//-/: }" 
            fi
        done
        
    elif [ "$mode" -eq 1 ]; then
        # ---------------------------------------------
        # MODE 1: Filtrar per DNI i Codi Cicle
        # ---------------------------------------------
        
        read -p "Introdueix el DNI a buscar (sense guions, amb lletra): " search_dni
        
        while true; do
          echo "===== Selecciona el codi del cicle de l'alumne que s'ha graduat ====="
		  echo "1) SMX123"
		  echo "2) GAD123"
		  echo "3) ACO123"
		  echo "4) MEC123"
		  echo "5) PRD123"
		  echo "6) ESA123"
		  echo "================================"
		  read -p "Selecciona una opció: " opcio

		  case $opcio in
		  # Assigno el codi autentic de cada cicle
		  1)   
		  	search_codi="SMX123"
			echo "Cicle escollit $search_codi" 
			break
			;;
		  2)   
			search_codi="GAD123"
			echo "Cicle escollit $search_codi" 
			break
			;;
		  3)   
			search_codi="ACO123"
			echo "Cicle escollit $search_codi" 
			break
			;;
		  4)   
			search_codi="MEC123"
			echo "Cicle escollit $search_codi" 
			break
			;;
		  5)   
			search_codi="PRD123"
			echo "Cicle escollit $search_codi" 
			break
			;;
		  6)   
			search_codi="ESA123"
			echo "Cicle escollit $search_codi" 
			break
			;;  
		  *) 
			echo "Opció no vàlida." 
			;;
		  esac
        done
        
        if [[ -z "$search_dni" || -z "$search_codi" ]]; then
            echo "DNI i Codi Cicle són obligatoris per a la cerca."
            return 1
        fi

        # Construïm el patró de cerca que es va emmagatzemar: DNI-CODI
        search_pattern="${search_dni}-${search_codi}-" 
        
        # Fem servir 'grep' per buscar el patró exactament
        # 'grep' retorna només les línies (registres) que coincideixen
        matching_record=$(echo "$all_records_text" | tr ';' '\n' | grep "^${search_pattern}" | head -1)

        echo "==========================================="
        if [[ -n "$matching_record" ]]; then
            echo "Registre Trobat:"
            # Format: DNI: Cicle: Nota
            echo " - ${matching_record//-/: }"
        else
            echo "No s'ha trobat cap registre amb DNI '$search_dni' i Codi Cicle '$search_codi'."
        fi
        echo "==========================================="
        
    else
        echo "Paràmetre de mode no vàlid. Utilitza '0' per a tots els registres o '1' per a filtrar."
    fi
}


# =======================================================================
# FUNCIÓ getCheckRecord: Comprova l'existència d'una nota (registre).
# Rep per paràmetre $1 (DNI) i $2 (Codi Cicle).
# RETORNA:
#   1 (Trobat) -> Si es troba exactament el registre DNI-CodiCicle.
#   0 (No Trobat) -> Si no s'ha trobat el registre o hi ha un error.
# =======================================================================
getCheckRecord() {
    local search_dni=$1
    local search_codi=$2
    local all_records_text=""
    local matching_record=""
    local found_flag=0 # 0 per defecte (No trobat)

    if [[ -z "$search_dni" || -z "$search_codi" ]]; then
        echo "Error: DNI i Codi Cicle són obligatoris per a la cerca." >&2
        return 0 # Retornem 0 en cas d'error d'input per ser conservadors
    fi
    
    echo "Consultant existència de registre per DNI '$search_dni' i Cicle '$search_codi'..."

    # 1. Crida la view function
    result=$(mxpy contract query $CONTRACT \
        --function getMarkStudent \
        --proxy $PROXY \
        2>/dev/null) 

    if [[ $? -ne 0 ]]; then
        echo "Error al consultar la funció getMarkStudent. Codi de sortida: $?." >&2
        return 0 # Retornem 0 en cas d'error de crida
    fi
    
    # 2. Parseig de l'HEX
    hex_data=$(echo "$result" | grep -o '"[^"]*"' | head -1 | tr -d '"')
    
    if [[ -z "$hex_data" || "$hex_data" == "" ]]; then
        echo "No s'ha pogut parsejar la resposta HEX." >&2
        return 0 # Retornem 0 en cas de parsing fallit
    fi

    # 3. Comprovació de registre buit des del contracte
    if [ "$hex_data" == "00" ]; then
        # "El contracte no té cap nota registrada."
        return 0 # Retorna 0 (No trobat)
    fi

    # 4. Descodificació
    all_records_text=$(hex_to_string "$hex_data")

    if [[ -z "$all_records_text" ]]; then
        echo "Descodificació a text buida." >&2
        return 0 # Retornem 0 si la descodificació falla
    fi
    
    # 5. Lògica de Cerca (DNI-CODI)
    search_pattern="${search_dni}-${search_codi}-" 
    
    # Fem servir 'grep' per buscar el patró (exemple: 12345678A-1-)
    matching_record=$(echo "$all_records_text" | tr ';' '\n' | grep "^${search_pattern}" | head -1)

    if [[ -n "$matching_record" ]]; then
        echo "Registre Trobat! ($matching_record)"
        found_flag=1
    else
        echo "No s'ha trobat el registre. Per tant, continua el procés d'inserció..."
        found_flag=0
    fi
    
    # El codi de sortida de Bash és 0 (EXIT_SUCCESS) per defecte,
    # però aquí l'utilitzem per indicar si s'ha trobat (1) o no (0).
    return $found_flag
}



# =======================================================================
# FUNCIÓ validate_dni: Valida el format i la lletra d'un DNI espanyol.
# Rep: $1 (DNI)
# Retorna: 'S' (Si és ERRONI: format O lletra incorrecta)
#          'N' (Si és CORRECTE: format I lletra correctes)
# =======================================================================
validate_dni() {
    local dni_input=$1
    local dni_format_regex='^[0-9]{8}[A-Z]$'
    local valid_letters='TRWAGMYFPDXBNJZSQVHLCKE' # Lletres de control ordenades

    # 1. Validació de Format (8 Dígits + 1 Lletra Majúscula)
    if [[ -z "$dni_input" || ! "$dni_input" =~ $dni_format_regex ]]; then
        # Format incorrecte o buit
        echo "S"
        return
    fi

    # 2. Obtenció de les parts
    # Extreu els 8 números
    local dni_number=${dni_input:0:8} 
    # Extreu la lletra proporcionada
    local dni_letter=${dni_input:8:1} 

    # 3. Càlcul de la lletra correcta (Mòdul 23)
    # Calculem el residu de dividir els 8 números per 23
    # Utilitzem 'expr' per fer el càlcul matemàtic
    local modulo=$(expr $dni_number % 23)

    # 4. Obtenció de la lletra esperada
    # La lletra correcta és la que es troba a la posició 'modulo' (0-indexada)
    local correct_letter=${valid_letters:modulo:1}

    # 5. Comprovació final
    if [[ "$dni_letter" == "$correct_letter" ]]; then
        echo "N"
    else
        # La lletra no coincideix amb els números
        echo "S"
    fi
}





# =======================================================================
# FUNCIÓ setMarkStudent: per guardar les notes de graduat dun alumne
# a la blockchain MultiversX
# =======================================================================
setMarkStudent() {
  local errordni="N"
  local dni=""
  local codicicle=""
  local opcio=""
  
  read -p "Introdueix el DNI de l'alumne que s'ha graduat (amb lletra majúscula i sense guions, ex: 47624357A ): " dni
  errordni=$(validate_dni "$dni")
  
  while true; do
    echo ""
    echo "===== Selecciona el codi del cicle de l'alumne que s'ha graduat ====="
    echo "1) SMX123"
    echo "2) GAD123"
    echo "3) ACO123"
    echo "4) MEC123"
    echo "5) PRD123"
    echo "6) ESA123"
    echo "================================"
    read -p "Selecciona una opció: " opcio

    case $opcio in
    # Assigno el codi autentic de cada cicle
      1)   
        codicicle="SMX123"
        echo "Cicle escollit $codicicle"
        echo "" 
        break
        ;;
	  2)   
        codicicle="GAD123"
        echo "Cicle escollit $codicicle" 
        echo ""
        break
        ;;
      3)   
        codicicle="ACO123"
        echo "Cicle escollit $codicicle" 
        echo ""
        break
        ;;
      4)   
        codicicle="MEC123"
        echo "Cicle escollit $codicicle" 
        echo ""
        break
        ;;
      5)   
        codicicle="PRD123"
        echo "Cicle escollit $codicicle" 
        echo ""
        break
        ;;
      6)   
        codicicle="ESA123"
        echo "Cicle escollit $codicicle" 
        echo ""
        break
        ;;  
      *) 
        echo "Opció no vàlida." 
        ;;
    esac
  done
  
  getCheckRecord "$dni" "$codicicle"
  
  # Captura el codi de sortida (exit code)
  # $? conté el valor retornat per l'última funció/comanda executada.
  # En el nostre cas: 1 (Trobat) o 0 (No Trobat/Error)
  exit_code=$?

  # Utilitza el codi de sortida per a la lògica condicional
  if [ $exit_code -eq 1 ]; then
      echo "Aquest registre amb DNI '$dni' i Cicle '$codicicle' JA EXISTEIX al contracte!!! Per tant, no l'afegirem!!!"
  else  
      while true; do
		echo ""
		echo "================================"
		read -p "Introdueix la nota de graduació, valors possibles: 5-10 " opcio

		case $opcio in
		# Assigno la nota correcta
			[5-9])
                nota=$opcio
                break
                ;;
            10)
                nota=$opcio
                break
                ;;
			*) 
				echo "Opció no vàlida." 
				;;
		esac
	 done
  
     if [ "$errordni" = "N" ]; then
       echo "Executo contracte amb parametres $dni $codicicle $nota"
       mxpy contract call $CONTRACT --pem $PEM --gas-limit=5000000 --value 0 --function setMarkStudent --arguments "str:$dni" "str:$codicicle" "str:$nota"  --proxy $PROXY --chain D --send
     else
	   echo "DNI incorrecte, no es dona d'alta aquest registre: $dni "
     fi
  fi
}



# =======================================================================
# FUNCIÓ clearMarks: per esborrar totes les notes introduides de la
# blockchain MultiversX
# =======================================================================
clearMarks() {
    echo "ATENCIÓ: Esborrant totes les dades de notes emmagatzemades..."

    # Executa la funció clearMarkStudent
    mxpy contract call $CONTRACT \
        --pem $PEM \
        --gas-limit=5000000 \
        --value 0 \
        --function clearMarkStudent \
        --proxy $PROXY \
        --chain D \
        --send

    if [[ $? -eq 0 ]]; then
        echo "Transacció enviada correctament. Les dades s'esborraran després de la confirmació del bloc."
    else
        echo "ERROR: No s'ha pogut enviar la transacció per esborrar les dades."
    fi
}



# =======================================================================
# ----------------MENú PRINCIPAL-----------------------------------------
# =======================================================================
while true; do
  echo ""
  echo "===== Menú RecordofMarks ====="
  echo "1) Mostrar la data límit per introduir notes aquest curs 25-26"
  echo "2) Consultar totes les notes de l'alumnat graduat fins al moment"
  echo "3) Consultar les notes d'un alumne concret per DNI i Codi Cicle"
  echo "4) Introduir notes d'un nou alumne que s'ha graduat (reservat per a owner)"
  echo "5) Esborrar totes les notes de l'alumnat que hi ha introduïdes (reservat per a owner per fer proves)"
  echo "0) Sortir"
  echo "================================"
  read -p "Selecciona una opció: " opcio

  case $opcio in
    1) get_deadline ;;
    2) getMarks 0 ;;
    3) getMarks 1 ;;
    4) setMarkStudent ;;
    5) clearMarks ;;
    0) echo "Adéu!"; break ;;
    *) echo "Opció no vàlida." ;;
  esac
done

