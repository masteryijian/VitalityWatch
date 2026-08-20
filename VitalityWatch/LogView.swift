import SwiftUI
import HealthKit

struct LogView: View {
    @EnvironmentObject private var model: HealthModel
    @State private var kcalInput = ""
    @State private var weightInput = ""
    @State private var bodyFatInput = ""
    @State private var saveMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("营养记录") {
                    TextField("能量（千卡）", text: $kcalInput)
                        .keyboardType(.decimalPad)
                    Button("写入健康 App") { saveEnergy() }
                }

                Section("身体成分（无体脂秤时可手动）") {
                    TextField("体重（kg）", text: $weightInput)
                        .keyboardType(.decimalPad)
                    TextField("体脂率（%）", text: $bodyFatInput)
                        .keyboardType(.decimalPad)
                    Button("写入健康 App") { saveBody() }
                }

                Section("数据导出") {
                    if let url = exportURL {
                        ShareLink(item: url) {
                            Label("导出 CSV", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Text("暂无数据可导出")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text("健康数据仅供个人参考，不构成医疗建议或诊断。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("记录")
            .alert("保存结果", isPresented: Binding(
                get: { saveMessage != nil },
                set: { if !$0 { saveMessage = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(saveMessage ?? "")
            }
        }
    }

    private var exportURL: URL? {
        let csv = HealthService.csv(from: model.days)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("vitality_export.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private func saveEnergy() {
        guard let kcal = Double(kcalInput) else {
            saveMessage = "请输入有效的能量值。"
            return
        }
        Task {
            do {
                try await model.service.writeQuantity(.dietaryEnergyConsumed, value: kcal, unit: .kilocalorie())
                saveMessage = "已写入 \(Int(kcal)) kcal。"
                kcalInput = ""
            } catch {
                saveMessage = error.localizedDescription
            }
        }
    }

    private func saveBody() {
        Task {
            do {
                if let weight = Double(weightInput) {
                    try await model.service.writeQuantity(.bodyMass, value: weight, unit: HKUnit.gramUnit(with: .kilo))
                }
                if let fat = Double(bodyFatInput) {
                    try await model.service.writeQuantity(.bodyFatPercentage, value: fat, unit: .percent())
                }
                saveMessage = "已写入体重/体脂。"
                weightInput = ""
                bodyFatInput = ""
            } catch {
                saveMessage = error.localizedDescription
            }
        }
    }
}
