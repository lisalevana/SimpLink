//
//  SimplifiedRoute.swift
//  SimpLing
//
//  Created by Aulia Nisrina Rosanita on 26/03/25.
//

import SwiftUI

struct SimpleRouteView: View {
    let routes = [
        "Intermoda - Sektor 1.3",
        "Greenwich - Sektor 1.3",
        "Intermoda - De Park (Rute 1)",
        "Intermoda - De Park (Rute 2)",
        "The Breeze - AEON - ICE - The Breeze",
        "Intermoda - Vanya Park - Intermode"
    ]
    
    let routeImages = [
        "(Rute 1) Intermoda - Sektor 1.3",
        "(Rute 2) Greenwich - Sektor 1.3",
        "(Rute 3) Intermoda - De Park (Rute 1)",
        "(Rute 4) Intermoda - De Park (Rute 2)",
        "(Rute 5) The Breeze - AEON - ICE - The Breeze",
        "(Rute 6) Intermoda - Vanya Park "
    ]
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Spacer().frame(height: 30)
                Text("Choose Route")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.leading)

                VStack(spacing: 16) {
                    ForEach(Array(zip(routes.indices, routes)), id: \.0) { index, route in
                        NavigationLink {
                            BusRouteView(routeName: route, routeImageName: routeImages[index])
                        } label: {
                            Text(route)
                                .font(.headline)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .frame(width: 380, height: 90)
                                .background(Color(uiColor: .systemGray6))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
                Spacer()
            }
            .navigationTitle("BSDLink Routes")
        }
    }
}

struct SimpleSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleRouteView()
    }
}

