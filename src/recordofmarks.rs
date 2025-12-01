#![no_std]

use multiversx_sc::derive_imports::*;
#[allow(unused_imports)]
use multiversx_sc::imports::*;
multiversx_sc::imports!();



#[type_abi]
#[derive(TopEncode, TopDecode, PartialEq, Clone, Copy)]
pub enum CodiCicles {
    SMX123,
    GAD123,
    ACO123,
    MEC123,
    PRD123,
    ESA123,
}

/// An empty contract. To be used as a template when starting a new contract from scratch.
#[multiversx_sc::contract]
pub trait Recordofmarks {
    #[init]
    fn init(&self, deadline: u64) {
        require!(
            deadline > self.get_current_time(),
            "Deadline can't be in the past"
        );
        self.deadline().set(deadline);
    }

    #[upgrade]
    fn upgrade(&self) {}



    // private
    fn get_current_time(&self) -> u64 {
        self.blockchain().get_block_timestamp()
    }

    
// Storage Mapper Deadline del curs
#[view(getDeadline)]
#[storage_mapper("deadline")]
fn deadline(&self) -> SingleValueMapper<u64>;


// 1. Definició del Storage Mapper
#[view(getMarkStudent)] 
#[storage_mapper("mark_student")] 
fn mark_student(&self) -> SingleValueMapper<ManagedBuffer>;

// ----------------------------------------------------------------------

// 2. Endpoint per Establir i Concatenar Dades
#[only_owner] 
#[endpoint(setMarkStudent)] 
fn set_mark_student(&self, dni: ManagedBuffer, codi_cicle: ManagedBuffer, nota: ManagedBuffer) { 

    // --- Validacions ---
    let current_time = self.blockchain().get_block_timestamp();
    require!(
        current_time < self.deadline().get(),
        "Curs Finalitzat" 
    );

    require!(
        !dni.is_empty() && !codi_cicle.is_empty() && !nota.is_empty(),
        "Tots els arguments (DNI, Codi Cicle, Nota) han de ser informats."
    );

    
    // --- Construcció del Nou Registre ---
    // 1. Definir els delimitadors
    let separator = ManagedBuffer::from(b"-"); // Per separar DNI, Codi i Nota
    
    // 2. Construir el nou valor (New_Data)
    // Format: DNI--CodiCicle--Nota
    let mut new_entry = dni;
    new_entry.append(&separator);
    new_entry.append(&codi_cicle);
    new_entry.append(&separator);
    new_entry.append(&nota);
    
    
    // --- Recuperació i Concatenació ---
    let old_data = self.mark_student().get(); 
    
    let final_data: ManagedBuffer = if old_data.is_empty() {
        // Cas 1: El nou registre és el primer valor
        new_entry
    } else {
        // Cas 2: Concatenem el nou registre a la llista existent
        
        let list_delimiter = ManagedBuffer::from(b";"); // Per separar registres
        
        let mut combined = old_data;
        combined.append(&list_delimiter);
        combined.append(&new_entry);
        combined
    };

    // 4. Guardar el nou valor concatenat
    self.mark_student().set(final_data); 
}
// ----------------------------------------------------------------------

// 3. Endpoint per Netejar/Esborrar les Dades
#[only_owner] 
#[endpoint(clearMarkStudent)] // Nou nom
fn clear_mark_student(&self) { 
    // El mètode .clear() elimina l'entrada d'emmagatzematge.
    self.mark_student().clear(); // Ús de mark_student()
}
        
}
//1782900000
//erd1qqqqqqqqqqqqqpgqu4rz3zpzhlattwzqgazlk6zttnrttj9cgdyqjgqxue