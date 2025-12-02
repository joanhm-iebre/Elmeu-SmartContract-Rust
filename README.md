# Elmeu-SmartContract-Rust
Es poden guardar les notes de l'alumnat de CFGM d'aquest curs 25-26 amb format:
DNI-CODICICLE-NOTA ==> Exemple ==> 47635487P-SMX123-10
El contracte permet enregistrar notes fins al 01-07-2026 que és quan acaba el curs. L'adreça del contracte és: erd1qqqqqqqqqqqqqpgqu4rz3zpzhlattwzqgazlk6zttnrttj9cgdyqjgqxue

Al fitxer client-recmark.sh he creat el següent menú per executar els endpoints i views d'aquest Smart contract (SC). El menú és:
===== Menú RecordofMarks ====="
1) Mostrar la data límit per introduir notes aquest curs 25-26
2) Consultar totes les notes de l'alumnat graduat fins al moment
3) Consultar les notes d'un alumne concret per DNI i Codi Cicle
4) Introduir notes d'un nou alumne que s'ha graduat (reservat per a owner)
5) Esborrar totes les notes de l'alumnat que hi ha introduïdes (reservat per a owner per fer proves)
0) Sortir

Les validacions d'introducció de dades com el valor correcte del DNI, valor correcte CodiCicle i valor numèric de nota correcte les he fet al client-recmark.sh ja que dintre del SC moltes operacions amb strings estan restringides pel seu cost computacional i els bucles augmenten també el cost computacional i per conseqüència també el GAS.

 

 
