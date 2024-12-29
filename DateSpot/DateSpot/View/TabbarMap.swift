import SwiftUI
import MapKit

struct TabbarMapView: View {
    
    var body: some View {
        NavigationView {
            // 지도 표시
            Map(){
                UserAnnotation()
                
                
            }
            
        }
    }
    
    
    
    
    
}
