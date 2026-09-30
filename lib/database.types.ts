export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type Database = {
  public: {
    Tables: {
      profiles: { Row: { id: string; username: string | null; display_name: string | null; avatar_url: string | null; created_at: string; updated_at: string }; Insert: { id: string; username?: string | null; display_name?: string | null; avatar_url?: string | null; created_at?: string; updated_at?: string }; Update: Partial<Database['public']['Tables']['profiles']['Insert']> }
      areas: { Row: { id: string; name: string; city: string; description: string | null; created_at: string; updated_at: string }; Insert: { id?: string; name: string; city: string; description?: string | null; created_at?: string; updated_at?: string }; Update: Partial<Database['public']['Tables']['areas']['Insert']> }
      cats: { Row: { id: string; created_by: string; nickname: string | null; description: string | null; created_at: string; updated_at: string }; Insert: { id?: string; created_by: string; nickname?: string | null; description?: string | null; created_at?: string; updated_at?: string }; Update: Partial<Database['public']['Tables']['cats']['Insert']> }
      cat_sightings: { Row: { id: string; cat_id: string; user_id: string; photo_path: string | null; note: string | null; area_id: string | null; exact_latitude: number | null; exact_longitude: number | null; public_latitude: number; public_longitude: number; spotted_at: string; created_at: string }; Insert: Omit<Database['public']['Tables']['cat_sightings']['Row'], 'id' | 'created_at'> & { id?: string; created_at?: string }; Update: Partial<Database['public']['Tables']['cat_sightings']['Insert']> }
      reports: { Row: { id: string; reporter_id: string; sighting_id: string; reason: string; description: string | null; status: string; created_at: string; resolved_at: string | null; resolved_by: string | null }; Insert: Omit<Database['public']['Tables']['reports']['Row'], 'id' | 'created_at' | 'resolved_at' | 'resolved_by'> & { id?: string; created_at?: string; resolved_at?: string | null; resolved_by?: string | null }; Update: Partial<Database['public']['Tables']['reports']['Insert']> }
    }
    Views: { public_sightings: { Row: { id: string; cat_id: string; nickname: string | null; description: string | null; photo_path: string | null; public_latitude: number; public_longitude: number; area_id: string | null; area_name: string | null; area_city: string | null; spotted_at: string; created_at: string } } }
    Functions: Record<string, never>
    Enums: Record<string, never>
    CompositeTypes: Record<string, never>
  }
}

export type PublicSighting = Database['public']['Views']['public_sightings']['Row']
