internal struct Colors {
    
    static let Background = UIColor.white
    
    struct Text {
        static let Default = UIColor.black
        static let Title = UIColor.black
        static let Subtitle = UIColor.gray
        static let AmountLabel = UIColor.black
        static let System = UIColor.black
        static let Error = UIColor.black
    }

    struct Buttons {
        
        struct Main {
            
            static let Default = UIColor.systemBlue
            static let Disabled = UIColor.gray
            static let Selected = UIColor.systemBlue
            
            struct Border {
                
                static let Default = UIColor.systemBlue
                static let Disabled = UIColor.gray
                static let Selected = UIColor.systemBlue
            }
        }
        
        struct PaymentMethod {
            
            static let Default = UIColor.white
            static let Disabled = UIColor.gray
            static let Selected = UIColor.systemBlue
            
            struct Border {
                
                static let Default = UIColor.black
                static let Disabled = UIColor.gray
                static let Selected = UIColor.systemBlue
            }
        }
    }
    
    struct Input {
        
        static let Background = UIColor.white
        static let Text = UIColor.black
        static let HintText = UIColor.gray
        static let ErrorText = UIColor.systemRed
        
        struct Border {
            
            static let Default = UIColor.black
            static let Disabled = UIColor.gray
            static let Selected = UIColor.systemBlue
        }
    }
}
