//
//  RouteImage.swift
//  SimpLing
//
//  Created by Aulia Nisrina Rosanita on 05/04/25.
//

import SwiftUICore
import SwiftUI

struct BusRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scale = 1.0
    @State private var angle = Angle(degrees: 0.0)
    
    let routeName: String
    let routeImageName: String
    
    var drag: some Gesture {
        DragGesture()
            .onEnded { value in
                if value.translation.height > 0 {
                    dismiss()
                    return
                }
            }
    }
    
    var doubleTap: some Gesture {
        TapGesture(count: 2)
            .onEnded {
            resetEffect()
        }
    }
    
    var zoom: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                if value != 0.0  {
                    scale = value.magnitude
                }
               
            }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with route title
                VStack {
                    Text(routeName)
                        .font(.system(size: 20, weight: .bold))
                        .padding(.top, 20)
                    
                    Divider()
                }
                .background(Color(.systemBackground))
                
                // Interactive route map
                    Image(routeImageName)
                        .resizable()
                        .scaledToFit()
                        .gesture(drag)
                        .gesture(doubleTap)
                        .scaleEffect(scale, anchor: .center)
                        .gesture(zoom)
            }
        }
            .navigationTitle("BSDLink Routes")
        }
    func resetEffect() {
        scale = 1.0
    }
}

struct BusRouteView_Previews: PreviewProvider {
    static var previews: some View {
        BusRouteView(routeName: "INTERMODA - SEKTOR 1.3",
                     routeImageName: "(Rute 1) Intermoda - Sektor 1.3")
        BusRouteView(routeName: "GREENWICH PARK - SEKTOR 1.3",
                     routeImageName: "(Rute 2) Greenwich - Sektor 1.3")
        BusRouteView(routeName: "TERMINAL INTERMODA - DE PARK (RUTE 1)",
                     routeImageName: "(Rute 3) Intermoda - De Park (Rute 1)")
        BusRouteView(routeName: "TERMINAL INTERMODA - DE PARK (RUTE 2)",
                     routeImageName: "(Rute 4) Intermoda - De Park (Rute 2)")
        BusRouteView(routeName: "THE BREZE - AEON - ICE - THE BREZE",
                     routeImageName: "(Rute 5) The Breeze - AEON - ICE - The Breeze")
        BusRouteView(routeName: "TERMINAL INTERMODA - VANYA PARK - INTERMODA",
                     routeImageName: "(Rute 6) Intermoda - Vanya Park ")
    }
}
