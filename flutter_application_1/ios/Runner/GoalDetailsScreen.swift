import SwiftUI

struct GoalDetailsScreen: View {
    @State private var targetWeight: String = ""
    @State private var desiredDuration: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(hex: "#E8EFCF")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Back Button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundColor(Color(hex: "#1D1B20"))
                            .frame(width: 40, height: 40)
                    }
                    .padding(.leading, 19)
                    .padding(.top, 31)
                    
                    // Title
                    Text("เป้าหมายของคุณคือ")
                        .font(.system(size: 32, weight: .regular))
                        .foregroundColor(.black)
                        .padding(.leading, 69)
                        .padding(.top, 38)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Subtitle
                    Text("การลดน้ำหนัก ควบคุมแคลอรี่")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color(hex: "#D76A3C"))
                        .padding(.leading, 65)
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Icon Circle
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 100, height: 100)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                            
                            AsyncImage(url: URL(string: "https://api.builder.io/api/v1/image/assets/TEMP/ac33d7d67c4029ca0fc3cd939f1cc859f2d46b05")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 70, height: 70)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 46)
                    
                    // Input Fields Container
                    VStack(alignment: .leading, spacing: 33) {
                        // Target Weight Field
                        HStack(spacing: 0) {
                            Text("เป้าหมายนํ้าหนัก")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 150, alignment: .leading)
                            
                            Spacer()
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(Color.white)
                                    .frame(width: 143, height: 29)
                                
                                TextField("", text: $targetWeight)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color.black.opacity(0.7))
                                    .placeholder(when: targetWeight.isEmpty) {
                                        Text("กรอกข้อมูล")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(Color.black.opacity(0.7))
                                    }
                                    .padding(.horizontal, 14)
                                    .frame(width: 143)
                            }
                        }
                        
                        // Desired Duration Field
                        HStack(spacing: 0) {
                            Text("ระยะเวลาที่ต้องการ")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 180, alignment: .leading)
                            
                            Spacer()
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(Color.white)
                                    .frame(width: 116, height: 29)
                                
                                TextField("", text: $desiredDuration)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color.black.opacity(0.7))
                                    .placeholder(when: desiredDuration.isEmpty) {
                                        Text("กรอกข้อมูล")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(Color.black.opacity(0.7))
                                    }
                                    .padding(.horizontal, 14)
                                    .frame(width: 116)
                            }
                        }
                    }
                    .padding(.leading, 43)
                    .padding(.trailing, 40)
                    .padding(.top, 70)
                    
                    Spacer(minLength: 180)
                    
                    // Next Button
                    HStack {
                        Spacer()
                        Button(action: {
                            // Handle next action
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color(hex: "#628141"))
                                    .frame(width: 259, height: 54)
                                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
                                
                                Text("ถัดไป")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                    .padding(.bottom, 57)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// TextField placeholder extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    GoalDetailsScreen()
}
