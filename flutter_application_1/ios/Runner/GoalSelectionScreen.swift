import SwiftUI

struct GoalSelectionScreen: View {
    @State private var selectedGoal: GoalOption? = .loseWeight
    @State private var navigateToDetails = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
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
                        Text("เป้าหมายของคุณคืออะไร?")
                            .font(.system(size: 32, weight: .regular))
                            .foregroundColor(.black)
                            .padding(.leading, 33)
                            .padding(.top, 37)

                        // Subtitle
                        Text("เลือกเป้าหมายเพื่อให้เราช่วยวางแผนที่เหมาะสม")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.black)
                            .padding(.leading, 50)
                            .padding(.trailing, 50)
                            .padding(.top, 20)

                        // Goal Options
                        VStack(spacing: 36) {
                        // Lose Weight Option
                        GoalOptionCard(
                            goal: .loseWeight,
                            title: "ลดน้ำหนัก",
                            subtitle: "ควบคุมแคลอรี่",
                            iconURL: "https://api.builder.io/api/v1/image/assets/TEMP/2b36cbc83f6282347dd67152d454841cc595df15",
                            isSelected: selectedGoal == .loseWeight,
                            backgroundColor: LinearGradient(
                                gradient: Gradient(colors: [Color.white, Color.white]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            selectedBackgroundColor: LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#DBA979"),
                                    Color(hex: "#D76A3C")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        ) {
                            selectedGoal = .loseWeight
                        }
                        
                        // Maintain Weight Option
                        GoalOptionCard(
                            goal: .maintainWeight,
                            title: "รักษาน้ำหนัก",
                            subtitle: "รักษาสมดุล สุขภาพดี",
                            iconURL: "https://api.builder.io/api/v1/image/assets/TEMP/caa3690bf64691cf18159ea72b5ec46944c37e66",
                            isSelected: selectedGoal == .maintainWeight,
                            backgroundColor: LinearGradient(
                                gradient: Gradient(colors: [Color.white, Color.white]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            selectedBackgroundColor: LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#4A90E2"),
                                    Color(hex: "#357ABD")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        ) {
                            selectedGoal = .maintainWeight
                        }
                        
                        // Build Muscle Option
                        GoalOptionCard(
                            goal: .buildMuscle,
                            title: "เพิ่มกล้ามเนื้อ",
                            subtitle: "ลดไขมัน",
                            iconURL: "https://api.builder.io/api/v1/image/assets/TEMP/3ac072bc08b89b53ec34785b4a25b0021535bdd8",
                            isSelected: selectedGoal == .buildMuscle,
                            backgroundColor: LinearGradient(
                                gradient: Gradient(colors: [Color.white, Color.white]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            selectedBackgroundColor: LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#F4C430"),
                                    Color(hex: "#E6B800")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        ) {
                            selectedGoal = .buildMuscle
                        }
                        }
                        .padding(.horizontal, 17)
                        .padding(.top, 67)

                        Spacer(minLength: 50)

                        // Next Button
                        HStack {
                            Spacer()
                            Button(action: {
                                navigateToDetails = true
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
            .navigationDestination(isPresented: $navigateToDetails) {
                GoalDetailsScreen()
            }
            .navigationBarHidden(true)
        }
    }
}

struct GoalOptionCard: View {
    let goal: GoalOption
    let title: String
    let subtitle: String
    let iconURL: String
    let isSelected: Bool
    let backgroundColor: LinearGradient
    let selectedBackgroundColor: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(isSelected ? selectedBackgroundColor : backgroundColor)
                    .frame(height: 116)
                
                HStack(spacing: 20) {
                    // Icon Circle
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 59, height: 58)
                        
                        AsyncImage(url: URL(string: iconURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 43, height: 43)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                    .padding(.leading, 12)
                    
                    // Text Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isSelected ? .white : .black)
                        
                        Text(subtitle)
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(isSelected ? .white : .black)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    // Check Icon
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 29))
                            .foregroundColor(.white)
                            .padding(.trailing, 19)
                    }
                }
                .padding(.vertical, 29)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum GoalOption: Equatable {
    case loseWeight
    case maintainWeight
    case buildMuscle
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    GoalSelectionScreen()
}
