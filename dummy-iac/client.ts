//client.ts

export interface GenerateInvitePayload {
    inviter_id: string;   // El UUID de quien invita (ej. Administrador o Vendedor Principal)
    company_id: string;   // ID de la empresa (ej. PRIME_CORE_ID)
    role: string;         // Rol dentro de la jerarquía (ej. 'vendedor', 'sub_vendedor')
    target_email?: string;// (Opcional) Correo a invitar. Si está vacío, solo devuelve el link.
}

export interface GenerateInviteResponse {
    message: string;
    invite_link: string;  // Enlace mágico (con JWT) que redirige al Frontend de registro
}

export interface RedeemInvitePayload {
    new_user_id: string;  // UUID generado por ORY Kratos tras un registro exitoso
    invite_token: string; // El token JWT que el frontend capturó de la URL de invitación
}

export interface RedeemInviteResponse {
    message: string;
    success: boolean;
}

export interface HierarchyResponse {
    hierarchy_root: string; // El UUID consultado
    subordinates: string[]; // Lista plana de UUIDs (cascada) bajo la jerarquía de este usuario
}

export class PrimeCoreSDK {
    private baseUrl: string;

    /**
     * @param baseUrl La URL base del API Gateway hacia los servicios Core
     */
    constructor(baseUrl: string = 'http://front.primecore.online') {
        this.baseUrl = baseUrl;
    }

    /**
     * Paso 1: Genera un "Magic Link" cifrado que contiene la relación de subordinación.
     */
    async generateInviteLink(payload: GenerateInvitePayload): Promise<GenerateInviteResponse> {
        const response = await fetch(`${this.baseUrl}/notifications/core/invites/generate`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            const errText = await response.text();
            throw new Error(`[PrimeCore SDK] Falló la generación de invitación: ${response.status} - ${errText}`);
        }

        return (await response.json()) as GenerateInviteResponse;
    }

    /**
     * Paso 2: Canjea el token tras el registro para consolidar la jerarquía en cascada (Keto).
     */
    async redeemInvite(payload: RedeemInvitePayload): Promise<RedeemInviteResponse> {
        const response = await fetch(`${this.baseUrl}/notifications/core/invites/redeem`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            const errText = await response.text();
            throw new Error(`[PrimeCore SDK] Falló el canje de invitación: ${response.status} - ${errText}`);
        }

        return (await response.json()) as RedeemInviteResponse;
    }

    /**
     * Auditoría: Retorna todos los subordinados en cascada para cruce de precompras.
     */
    async getHierarchy(userId: string): Promise<HierarchyResponse> {
        const response = await fetch(`${this.baseUrl}/notifications/core/hierarchy/${userId}`, {
            method: 'GET',
            headers: { 'Accept': 'application/json' }
        });

        if (!response.ok) {
            const errText = await response.text();
            throw new Error(`[PrimeCore SDK] Falló la consulta de jerarquía: ${response.status} - ${errText}`);
        }

        return (await response.json()) as HierarchyResponse;
    }
}

// ==========================================
// EJEMPLO DE USO (Para los equipos de producto)
// ==========================================
/*
import { PrimeCoreSDK } from './primecore-core-client';

const sdk = new PrimeCoreSDK();

async function flujoCompletoB2B() {
    // 1. El Admin hace clic en "Invitar Vendedor"
    const invitacion = await sdk.generateInviteLink({
        inviter_id: "UUID-DE-ADMIN",
        company_id: "PRIME_PRECOMPRAS_ID",
        role: "vendedor"
    });
    console.log("Copiar y enviar por WhatsApp:", invitacion.invite_link);
    // Resultado: https://front.primecore.online/registro?invite_token=eyJhbGciOiJIUzI1Ni...

    // 2. [Fuera del Backend] El usuario abre el link, llena sus datos y se registra en Kratos.
    // El Frontend envía el ID nuevo y el token capturado de la URL hacia este Backend.

    // 3. El Backend recibe confirmación y amarra al usuario a la empresa del admin
    await sdk.redeemInvite({
        new_user_id: "UUID-RECIEN-CREADO",
        invite_token: "eyJhbGciOiJIUzI1Ni..."
    });

    // 4. Cuando el admin quiera ver el consumo de precompras de toda su red:
    const arbol = await sdk.getHierarchy("UUID-DE-ADMIN");
    console.log("Hacer SELECT sum(consumo) WHERE user_id IN:", arbol.subordinates);
}
*/