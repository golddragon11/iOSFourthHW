import SwiftUI
import UIKit

let height = CGFloat(800)

var sum = 0
var sums = [0,0,0,0,0,0]
var max: Double = 0
var angles = [Angle(degrees: 0), Angle(degrees: 0), Angle(degrees: 0), Angle(degrees: 0), Angle(degrees: 0), Angle(degrees: 0), Angle(degrees: 360)]

func calculateSum() {
    let spendingsData = SpendingData()
    sum = 0
    for i in 0..<sums.count {
        sums[i] = 0
    }
    for i in 0..<spendingsData.spendings.count {
        sum += spendingsData.spendings[i].amount
        sums[spendingsData.spendings[i].type.rawValue] += spendingsData.spendings[i].amount
    }
}

func calculateAngles() {
    var temp:Double = 0.0
    for i in 1...sums.count {
        if max < Double(sums[i-1]) {
            max = Double(sums[i-1])
        }
        temp += Double(sums[i-1])
        angles[i] = Angle(degrees: temp*360.0/Double(sum))
    }
}

struct Spending: Identifiable, Codable {
    var id = UUID()
    var amount: Int
    var note: String
    var type: Type
}

enum Type: Int, Codable, CaseIterable {
    case transportation = 0, food = 1, dessert = 2, drink = 3, entertainment = 4, other = 5
    var description: String {
        switch self {
        case .transportation: return "交通"
        case .food: return "正餐"
        case .dessert: return "點心"
        case .drink: return "飲料"
        case .entertainment: return "娛樂"
        case .other: return "其它"
        }
    }
}

class SpendingData: ObservableObject {
    @AppStorage("spendings") var spendingsData: Data?
    @Published var spendings = [Spending]() {
        didSet {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(spendings)
                spendingsData = data
            } catch {
                
            }
        }
    }
    init() {
        if let spendingsData = spendingsData {
            let decoder = JSONDecoder()
            if let decodedData = try? decoder.decode([Spending].self, from: spendingsData) {
                spendings = decodedData
            }
        }
    }
}

struct SpendingEditor: View {
    @Environment(\.presentationMode) var presentationMode
    var spendingsData: SpendingData
    @State private var price = ""
    @State private var note = ""
    @State private var selectedType = Type.transportation
    @State private var showAlert = false
    var body: some View {
        NavigationView {
            Form {
                HStack {
                    Text("價錢")
                    TextField("", text: $price)
                        .keyboardType(.decimalPad)
                }
                VStack {
                    HStack {
                        Text("花費項目")
                        Spacer()
                    }
                    Picker("花費項目", selection: $selectedType) {
                        ForEach(Type.allCases, id: \.self) { (value) in
                            Text(value.description)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                HStack {
                    Text("備註")
                    TextField("", text: $note)
                }
            }
            .navigationBarTitle("新增花費")
            .navigationBarItems(leading: Button("Cancel") {
                self.presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                if price.contains(".") || price == "" {
                    showAlert = true
                }
                else {
                    let spending = Spending(amount: Int(price) ?? 0, note: note, type: selectedType)
                    spendingsData.spendings.insert(spending, at: 0)
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
            .alert(isPresented: $showAlert) { () -> Alert in
                return Alert(title: Text((price.contains(".")) ? "價錢必須為整數!" : "請輸入價錢!"))
            })
        }
    }
}

struct ExpenseDetail: View {
    @ObservedObject var spendingsData = SpendingData()
    @State private var showEditSpending = false
    var body: some View {
        NavigationView {
            Form {
                ForEach (spendingsData.spendings) { (spending) in
                    HStack {
                        Text("\(spending.type.description)")
                        if spending.note != "" {
                            Text("->  \(spending.note)")
                        }
                        Spacer()
                        Text("$\(spending.amount)")
                    }
                }
                .onDelete(perform: { indexSet in
                    spendingsData.spendings.remove(atOffsets: indexSet)
                })
                .onMove(perform: { indices, newOffset in
                    spendingsData.spendings.move(fromOffsets: indices, toOffset: newOffset)
                })
            }
            .navigationBarTitle("Expenses")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showEditSpending = true
                    }, label: {
                        Image(systemName: "plus.circle.fill")
                    })
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .disabled(spendingsData.spendings.count == 0)
                }
            })
        }
        .sheet(isPresented: $showEditSpending) {
            SpendingEditor(spendingsData: spendingsData)
        }
    }
}

struct PieChart: Shape {
    var startAngle: Angle
    var endAngle: Angle
    func path(in rect: CGRect) -> Path {
        Path { (path) in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            path.move(to: center)
            path.addArc(center: center, radius: rect.midX, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        }
    }
}

struct ExpenseSummary: View {
    @StateObject var spendingsData = SpendingData()
    @State private var trimEnd: CGFloat = 0
    @State private var showChart = false
    var body: some View {
        VStack {
            TabView {
                ZStack {
                    PieChart(startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 0))
                    if (showChart == true) {
                        PieChart(startAngle: angles[0], endAngle: angles[1])
                            .foregroundColor(.green)
                            .animation(.linear(duration: 2))
                        PieChart(startAngle: angles[1], endAngle: angles[2])
                            .foregroundColor(.orange)
                            .animation(.linear(duration: 2))
                        PieChart(startAngle: angles[2], endAngle: angles[3])
                            .foregroundColor(.red)
                            .animation(.linear(duration: 2))
                        PieChart(startAngle: angles[3], endAngle: angles[4])
                            .foregroundColor(Color(.cyan))
                            .animation(.linear(duration: 2))
                        PieChart(startAngle: angles[4], endAngle: angles[5])
                            .foregroundColor(.blue)
                            .animation(.linear(duration: 2))
                        PieChart(startAngle: angles[5], endAngle: angles[6])
                            .foregroundColor(.gray)
                            .animation(.linear(duration: 2))
                    }
                }
                .animation(.easeIn(duration: 2))
                .padding(.horizontal)
                HStack {
                    Spacer()
                    Rectangle()
                        .foregroundColor(.green)
                        .frame(width: 40, height: CGFloat(sums[0])/CGFloat(max)*height)
                        .position(x: 25, y: 513)
                    Rectangle()
                        .foregroundColor(.orange)
                        .frame(width: 40, height: CGFloat(sums[1])/CGFloat(max)*height)
                        .position(x: 25, y: 513)
                    Rectangle()
                        .foregroundColor(.red)
                        .frame(width: 40, height: CGFloat(sums[2])/CGFloat(max)*height)
                        .position(x: 25, y: 513)
                    Rectangle()
                        .foregroundColor(Color(.cyan))
                        .frame(width: 40, height: CGFloat(sums[3])/CGFloat(max)*height)
                        .position(x: 25, y: 513)
                    Rectangle()
                        .foregroundColor(.blue)
                        .frame(width: 40, height: CGFloat(sums[4])/CGFloat(max)*height)
                        .position(x: 25, y: 513)
                    Rectangle()
                        .foregroundColor(.gray)
                        .frame(width: 40, height: CGFloat(sums[5])/CGFloat(max)*height)
                        .position(x: 25, y: 513)
//                    Spacer()
                }
                .frame(alignment: .bottom)
            }
            .tabViewStyle(PageTabViewStyle())
            HStack {
                Text("總花費 $\(sum)")
                    .font(.title)
                    .padding()
                Spacer()
            }
            HStack {
                Color(.green)
                    .clipShape(Circle())
                    .frame(width: 25, height: 25)
                Text("交通")
                Color(.orange)
                    .clipShape(Circle())
                    .frame(width: 25, height: 25)
                Text("正餐")
                Color(.red)
                    .clipShape(Circle())
                    .frame(width: 25, height: 25)
                Text("點心")
                Spacer()
            }
            .padding(.horizontal)
            HStack {
                Color(.cyan)
                    .clipShape(Circle())
                    .frame(width: 25, height: 25)
                Text("飲料")
                Color(.blue)
                    .clipShape(Circle())
                    .frame(width: 25, height: 25)
                Text("娛樂")
                Color(.gray)
                    .clipShape(Circle())
                    .frame(width: 25, height: 25)
                Text("其它")
                Spacer()
                Button(action: {
                    showChart = false
                    calculateSum()
                    calculateAngles()
                    showChart = true
                }, label: {
                    Image(systemName: "arrow.counterclockwise")
                })
            }
            .padding()
        }
        .onAppear {
            calculateSum()
            calculateAngles()
            showChart = true
        }
        .onDisappear() {
            calculateSum()
            calculateAngles()
            showChart = false
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            ExpenseSummary()
                .tabItem {
                    Text("Summary")
                    Image(systemName: "chevron.up.circle")
                }
            ExpenseDetail()
                .tabItem {
                    Text("Detail")
                    Image(systemName: "ellipsis.circle")
                }
        }
//        PieChart(startAngle: Angle(degrees: 50), endAngle: Angle(degrees: 200))
//            .animation(.linear)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
//        ExpenseDetail()
        ContentView()
//            .preferredColorScheme(.dark)
    }
}

/*
 CRUD
 MVVM
 @ObservableObject, @Published, @StateObject
 @Environment(\.presentationMode)
 @AppStorage, Codable, JSONEncoder, JSONDecoder
 chart
 onMove
 disabled
 animation
 data search
 */

// Create Read Update Delete
// Animation
// Chart
// Move
