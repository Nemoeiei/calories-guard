export interface AuthState {
  user_id: number
  username: string
  email: string
  role_id: number
}

export interface Food {
  food_id: number
  food_name: string
  calories: number
  protein: number
  carbs: number
  fat: number
  image_url?: string | null
  allergy_flag_ids?: number[]
}

export interface FoodFormData {
  food_name: string
  calories: string
  protein: string
  carbs: string
  fat: string
  image_url: string
}

export interface TempFood {
  tf_id: number
  food_name: string
  calories: number | null
  protein: number | null
  carbs: number | null
  fat: number | null
  user_id: number
  requester_name: string
  submitted_at: string
  is_verify: boolean
  verified_by: number | null
  verified_at: string | null
}

export interface FoodRequest {
  request_id: number
  food_name: string
  status: string
  calories: number | null
  protein: number | null
  carbs: number | null
  fat: number | null
  ingredients_json: string | null
  created_at: string
  requester_name: string
}
