//
//  3DSConstants.swift
//  PrimerSDK_Tests
//
//  Created by Evangelos Pittas on 18/6/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation


struct ThreeDSConstants {
    
    static let paymentMethodJSON: String = """
            {
              "paymentInstrumentData" : {
                "binData" : {
                  "accountFundingType" : "UNKNOWN",
                  "issuerCurrencyCode" : null,
                  "accountNumberType" : "UNKNOWN",
                  "prepaidReloadableIndicator" : "NOT_APPLICABLE",
                  "productUsageType" : "UNKNOWN",
                  "productCode" : "OTHER",
                  "productName" : "OTHER",
                  "issuerName" : null,
                  "regionalRestriction" : "UNKNOWN",
                  "network" : "OTHER",
                  "issuerCountryCode" : null
                },
                "isNetworkTokenized" : false,
                "expirationMonth" : "02",
                "expirationYear" : "2022",
                "cardholderName" : "John Snow",
                "last4Digits" : "0008",
                "network" : "other"
              },
              "vaultData" : {
                "customerId" : "customer_1"
              },
              "threeDSecureAuthentication" : {
                "responseCode" : "AUTH_SUCCESS",
                "protocolVersion" : "2.1.0",
                "reasonText" : null,
                "reasonCode" : null,
                "challengeIssued" : true
              },
              "tokenType" : "MULTI_USE",
              "token" : "KaQEZ_RdR2G38azRUVCc3HwxNjIzODUxMTI1",
              "analyticsId" : "hCiK4Z8dVJq1wWWPnX53hm4t",
              "paymentInstrumentType" : "PAYMENT_CARD"
            }
        """
    
    static let beginAuthResponseStr: String = """
        {
          "token" : {
            "paymentInstrumentData" : {
              "binData" : {
                "accountFundingType" : "UNKNOWN",
                "issuerCurrencyCode" : null,
                "accountNumberType" : "UNKNOWN",
                "prepaidReloadableIndicator" : "NOT_APPLICABLE",
                "productUsageType" : "UNKNOWN",
                "productCode" : "OTHER",
                "productName" : "OTHER",
                "issuerName" : null,
                "regionalRestriction" : "UNKNOWN",
                "network" : "OTHER",
                "issuerCountryCode" : null
              },
              "isNetworkTokenized" : false,
              "expirationMonth" : "02",
              "expirationYear" : "2022",
              "cardholderName" : "John Snow",
              "last4Digits" : "0008",
              "network" : "other"
            },
            "vaultData" : null,
            "threeDSecureAuthentication" : {
              "responseCode" : "AUTH_SUCCESS",
              "protocolVersion" : "2.1.0",
              "reasonText" : null,
              "reasonCode" : null,
              "challengeIssued" : true
            },
            "tokenType" : "MULTI_USE",
            "token" : "KaQEZ_RdR2G38azRUVCc3HwxNjIzODUxMTI1",
            "analyticsId" : "hCiK4Z8dVJq1wWWPnX53hm4t",
            "paymentInstrumentType" : "PAYMENT_CARD"
          },
          "authentication" : {
            "acsSignedContent" : "eyJhbGciOiJFUzI1NiIsIng1YyI6WyJNSUlCeFRDQ0FXdWdBd0lCQWdJSU9IaW42MUJaZDIwd0NnWUlLb1pJemowRUF3SXdTVEVMTUFrR0ExVUVCaE1DUkVzeEZEQVNCZ05WQkFvVEN6TmtjMlZqZFhKbExtbHZNU1F3SWdZRFZRUURFeHN6WkhObFkzVnlaUzVwYnlCemRHRnVaR2x1SUdsemMzVnBibWN3SGhjTk1qRXdOREkyTVRJd05ERTVXaGNOTWpZd05USTJNVEl3TkRFNVdqQkZNUXN3Q1FZRFZRUUdFd0pFU3pFVU1CSUdBMVVFQ2hNTE0yUnpaV04xY21VdWFXOHhJREFlQmdOVkJBTVRGek5rYzJWamRYSmxMbWx2SUhOMFlXNWthVzRnUVVOVE1Ga3dFd1lIS29aSXpqMENBUVlJS29aSXpqMERBUWNEUWdBRWN6c3EvVVRzU2VSWUxGQnl2Z2JjclJpSnZ3Wm5RbW9zdE5KZ2w2aTQvMHJyOXhHTUQrZ2NxclljYnZGVEVKSVZIczFpNTU3UEd3Mm96SFFtWnIvUjFxTkJNRDh3RGdZRFZSMFBBUUgvQkFRREFnT29NQXdHQTFVZEV3RUIvd1FDTUFBd0h3WURWUjBqQkJnd0ZvQVVvZWphd1dEa1VyMUZWd3hhY0sxMDYyNm1rWXN3Q2dZSUtvWkl6ajBFQXdJRFNBQXdSUUlnR3ZLNDRiWEw2UUQxY1AzMjJhdkhSam1ENFQxYTFlbDN2ZjJ0dHNzWG9lY0NJUUN0bG53djV0WGRkSkpwaElnY3hqRzdEQThIcHAwendxUk9lRjNEZXpNdnJBPT0iLCJNSUlCN0RDQ0FaR2dBd0lCQWdJSUdJbllUVVdYNFgwd0NnWUlLb1pJemowRUF3SXdTVEVMTUFrR0ExVUVCaE1DUkVzeEZEQVNCZ05WQkFvVEN6TmtjMlZqZFhKbExtbHZNU1F3SWdZRFZRUURFeHN6WkhObFkzVnlaUzVwYnlCemRHRnVaR2x1SUhKdmIzUWdRMEV3SGhjTk1qRXdOREkyTVRJd05ERTVXaGNOTWpZd05USTJNVEl3TkRFNVdqQkpNUXN3Q1FZRFZRUUdFd0pFU3pFVU1CSUdBMVVFQ2hNTE0yUnpaV04xY21VdWFXOHhKREFpQmdOVkJBTVRHek5rYzJWamRYSmxMbWx2SUhOMFlXNWthVzRnYVhOemRXbHVaekJaTUJNR0J5cUdTTTQ5QWdFR0NDcUdTTTQ5QXdFSEEwSUFCSDhzYWpzaXl3RlhXUlpPVDdGa1I3eFlyb3VHK2JVbUh2NUYyVk1KYmdJQlBxUzJFdzRWT0p4TEI4QTU5QnZSdmF6WmF0TGt5NktnbmpmZEhvOXJrdEtqWXpCaE1BNEdBMVVkRHdFQi93UUVBd0lCaGpBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJTaDZOckJZT1JTdlVWWERGcHdyWFRyYnFhUml6QWZCZ05WSFNNRUdEQVdnQlMxeGRvRjFlN0VqNHBRaUxCL24xVFN3MDBpSVRBS0JnZ3Foa2pPUFFRREFnTkpBREJHQWlFQXg1MWdzK0pSN0RteVQrV2RPeFhjdHVDT0srSFJwbkl6U0g3WTlBZmM5eGNDSVFDMWg4NHVoRjljbjMxR0JjSGhTTGd5RkQvMk5DYnJ1b0g3RGVGa2RoQk1BQT09IiwiTUlJQnlqQ0NBWENnQXdJQkFnSUlXbTNsWW5ScGcva3dDZ1lJS29aSXpqMEVBd0l3U1RFTE1Ba0dBMVVFQmhNQ1JFc3hGREFTQmdOVkJBb1RDek5rYzJWamRYSmxMbWx2TVNRd0lnWURWUVFERXhzelpITmxZM1Z5WlM1cGJ5QnpkR0Z1WkdsdUlISnZiM1FnUTBFd0hoY05NakV3TkRJMk1USXdOREU1V2hjTk1qWXdOVEkyTVRJd05ERTVXakJKTVFzd0NRWURWUVFHRXdKRVN6RVVNQklHQTFVRUNoTUxNMlJ6WldOMWNtVXVhVzh4SkRBaUJnTlZCQU1UR3pOa2MyVmpkWEpsTG1sdklITjBZVzVrYVc0Z2NtOXZkQ0JEUVRCWk1CTUdCeXFHU000OUFnRUdDQ3FHU000OUF3RUhBMElBQkRpa2kzWjc0SHNSNEc1ZWpxd2szMVNUQTBKWnlXZEJiemZrcExoeGxOZXBKbXpXL2xLdmdwSjV3MWFiV3ltTnYra1ExZXZkb0NaM3hQcldESDNPdithalFqQkFNQTRHQTFVZER3RUIvd1FFQXdJQmhqQVBCZ05WSFJNQkFmOEVCVEFEQVFIL01CMEdBMVVkRGdRV0JCUzF4ZG9GMWU3RWo0cFFpTEIvbjFUU3cwMGlJVEFLQmdncWhrak9QUVFEQWdOSUFEQkZBaUF4ZUlaRCtnZkZWc1FuYmJPSDdsMDR2OGV1cTBOODJnRzh1bUJhRmwrQVZ3SWhBSVZEaUc0bkxrTDE4N2NsSG41TXcyQUFMSGgxeFNTZlNCR2JkVW11Q2Q3YiJdfQ.eyJhY3NVUkwiOiJodHRwczovL2Fjcy5zYW5kYm94LjNkc2VjdXJlLmlvL3Nkay9jaGFsbGVuZ2UvbWFudWFsIiwiYWNzRXBoZW1QdWJLZXkiOnsia3R5IjoiRUMiLCJjcnYiOiJQLTI1NiIsIngiOiJyT2tVSzExTGxDdkVHc1l6ZDZNMTV3OFc3SHRiQzJ4QUxreUxXbzRTLXk4IiwieSI6ImtvNUxtTFFKWk1qTHcyYXZlN2VMS2lJMDRuaTBjOGFKRm1jUkplRG1ZVFEifSwic2RrRXBoZW1QdWJLZXkiOnsieSI6ImV3NFVpMkdmUGNYbmU0aTgzckZjWG9hYTluSVdpemlVUmRFaHJNV2lzNTQiLCJ4IjoiQ0VOX0VCZTA4OV9rUWMyZFhxSE83bVNKbHdlX1hSSTRuOEZGRTRJM0hIayIsImt0eSI6IkVDIiwiY3J2IjoiUC0yNTYifX0.QcM3FtdLAYJSHjK3qHfZHCWo3da9mPmcjQSkSXR5QiNIQOw4sQw5xsZ1d-leTVoG-Y43t38DwPWotnmq1EOsFw",
            "dsTransactionId" : "3178fe94-f5ab-459a-9664-bfbc2fbdd993",
            "acsReferenceNumber" : "3ds_acs_provider",
            "acsOperatorId" : "3ds_operator_id",
            "eci" : null,
            "acsRenderingType" : {
              "acsInterface" : "01",
              "acsUiTemplate" : "02"
            },
            "protocolVersion" : "2.1.0",
            "transactionId" : "c1412108-71fc-42ab-a42b-a9d637a4c582",
            "statusUrl" : "http://localhost:8081/sdk/3ds/KaQEZ_RdR2G38azRUVCc3HwxNjIzODUxMTI1/status",
            "responseCode" : "CHALLENGE",
            "dsReferenceNumber" : "3dsecureio-standin-ds",
            "acsChallengeMandated" : false,
            "acsTransactionId" : "acs_transaction_id"
          },
          "resumeToken" : "bc884d5c-1f5a-4905-9aaa-166fb90eb603"
        }
        """
    
    static let sdkAuthResponseStr = """
        {
            "sdkAppId": "ee4efcd7-f5a8-45b2-8a87-fd0d01998c45",
            "sdkTransactionId": "8ddb9bfc-cf11-446a-bc2b-b37789f4c5f7",
            "sdkTimeout": 10,
            "sdkEphemPubKey": "emphemeralKeyJSONString",
            "sdkReferenceNumber": "3DS_SDK_REF",
            "sdkEncData": "eyJhbGciOiJkaXIiLCJlbmMiOiJBMTI4Q0JDLUhTMjU2IiwiZXBrIjp7InkiOiJjU0gyRFNyM1ZNYVJIbk9wNEU5QTBZSENpckRLaDhSdnR2YVZEa25WazE0IiwieCI6ImtUMlJZcC0zb3dMTGQ0TDZ2WXJNSTZBam9nbElHbzdnaWlKZTNHRnJyS2siLCJrdHkiOiJFQyIsImNydiI6IlAtMjU2In0gfQ..ijjcHathFGOj-M3fgL04ww.Wt7eJxFFW0DqX4V6siz-lgYLzhx0JAQ8aIIdqcFZD9_VGzIAYwmZgO1cQtDDajHwo2ROCLAKWjdXombCaaVnzEl-HmsaqiDWZh_WjjQhtsvJNcYyiT_6bBpHXQbZ5_6lVtZdAOUcRrhr1fB8x5OMp2pmh_riSzikVZXBmp5MmHky_u6H2vZHCp3I73VMt2O6VcGiQEVTm49fxWUq1qeWn6qtzYmln0Yp_8Zk4xbqnTYD2DiYxGKpIVZjp33BCNvqPPEF2EBTJtuJd919jEocH8P0eWQPJPUD4yjUWERd3mdlvwkoeqrxeLN6ghXMQVdy48EnYDPOLjmDRTlIexhs6XGm57pLGBOGTIloh1f1zxamaRXsnLOzwToYIGzvC2saw7DCBxGzYZjTRLDMpcA5tCALhJ-qvQubHhrQeU5fSZbMr91scN56wWRZkn1RUIAOvSCMy-Z0_N4KARC3SMS-kGofd7Dw0fM9kThObBeNlnXCCzb5C3RwgWwa2AyBXPlCrpXOdJazwW7a4hoSS8QpD9Fjs1iAIuTiF4FERawNUJ7x78mCEKvrpmPRFE4pJ8O5oS_56d7w7TLULxVGL78QBQ_e54XpmUDMwALQc2tLtRVepVUE8g4-EIOprCvl9TCsE4zd8kH8BIgo5BxXmQj5ct6G5AZrh3eqQ__4vCSlN-j8_oWX_qjmblssNLHqvowzXM2WWBJF-5BRf0AqjlHYQF0Oi008frbbbtHD4Pbf4-3klqqDc0EjJSIEvzYmfM89z7R_DdbH9ecjBUjMtzsEAgPtoy8HMEikHTt8Iie-5Hd_X-JrxbwQrpcLzZFez4gPjF_mFNpGW46TrKw-Or9kUWlSPJyJKI2NsNAtrx5J6VG4IlTCwG1v_PvXXFwmMxpCCSG7VGW9EVdwesq67wNAqbc2og1dsfltzKopUqZmcet65XdlpevI0eNN_vg2niSixJewtkIlrVG0UCKZ2P0IYuoeWzmI8dBMvQoE3t4Zl3E5mJm7L8iNmn5H0WAnwgbwots5-BV4LFOALrM1LhpbThlP_SMIBO4RgKKI_2wcAhHa2HxfWZ3xqVV-1nNFuUBnviJ4BTDJlPLtQinD1TZzr1RB0iu781buq5npwrav0jNyxm8lx8jR7Fcgajj2dbEDjtg8xW1N6xK6__jjjZdwvrTc2CMbtNE0vdiybKxT2oldADvwFYW4Meciou_DogSkmGf5jogXdRILoOKrHDrBaVkMC3ixzGTQtDBa0tG8mLi1f8o9FfJHrQBUBhBhMcrs4BuimWjV5CziZPkj7skFw3rhK8F9lrg6Nig_GA3NXMxXONWvm9qtPKfcGbXvrqtpzsTkB7mJGJnxH8GsIoCB-FJfj2rHOrpc9px1BBwv2-Qfjn7-w3X6cl7DyYzFA90_c4JDU3gQ_sftr2YdA2Bnw3wNPyntHx2wDH_buq-n1gK75uRQFtGS46W3ZQHpV532wzEKgHPiY1492dsCA8wPziQOU1xG3MAwkzn6T8xYG-uezSS0LcXLxsIN2n_cBn_3BDmoqFMl5VNKZsEEKGF82xxwCAMVW5waFIRsHv6WCaFvv-xipqVGb85syEBwAuEB-lOAFdPx927TcyxJcnFgBjkzjGNxLEgrHBfPs_4ZIwvDrYiYAl62oH9v7yPoN2TUNLXcF4WA4IJs9WPuoWv3jC0HVzq9jvfyLmKCldAuXINKOu_emqIMhrda4P_HF_jC0ow8qOXYCx90snzXsCwBfgoXvvqmXCoCR8w5vXt-wB8Bef_rTtOtxh0rI-ij3lpR4Zi3Rnaa_tN3c74v2zt7CB1rxzhmG2TvTksDiO2KHSsdFtqcPF0hDWpU5-xUyj3ma0q0NESZoTbjqi-Pr0tPumsnovrGpjC4iWL7VXo-vdZuQWOyh7aji7KURt2yTmcXcLTLenOtLBP9nQ97lX9RJrjTIeBywiXBAm54i5Ej6pQpp6iBu_G5cE6D17TDl7bkMIeraoyRPaRhJMaomQ_RdOlaWsQJUp3IJq7odDgCI1Y6hP_yay5gFzUTRDsm-epKgbokpMz8eA5vo7ikPWhADP78TzEzr1ruFU_ttRhQxvJGf7Jl7amxkbMXsMTTdMO4oAO8B3axnuivT0qCi76ET41pzFIblI7qJgd2OcJCx4r97fcxUB25ZH6458h7uVPNoqNup5gMN9WRtQVSx_j5CF9L-WkZqNnAwMKqbafY3XcTzIMWNL_gPeMOuDYhtGQ2y9ePL_iEX09CZWc-NMNUQwsV-xk0wkGsXlkp50q0YZNuvU7fKpzc9E-1xqhdZujCeZvkopFK4fEhqtm6QwZRmdXUF5ivt_g7p0a-sTKbDXdzPpGU_vS7vdnhZMdqrm9stWpEfHJO5PVPIuWOslqMrnemXkj7tq3VI8v7zvVn74_BrISuWsu-w6XquJ4CbBQMN7GyB8jRq4SkUdA5DOt8RXv9sRmxmiLErFADh9EXeVqUgB3gPk7fMaH_AIgNotAcwaEBof0jAmneP052oeofLbUIvomOcqYW2PGnF1XHN6umOGFwUJHKOiWT6Rk4JOODpd-w1OMLB0-s8uTCgu2qpicLgdmRTTCL9XdaojKHdBHI9V760ayzqB96OXnBqu2fAh4_fdZxh_Zof6UxY928_D61Wl_iT2Dm2jo-J5SEfMGwIm20q8KzQ26CJ0W5JQFhZ8iXfielQjVSI9_BqMX7H7xl0zCFERxhNjDctXxGTGxLLrELsSCd9g57W9_qJZIYHZ2fRY1Iyq5zytiNYj9TNKI3WwrVm7UtQTiNsYManbljzj6-X_5yWNVy5xJfVmokj-pQZah46w21VxyiPqJhlAE1qg32ntz7b7FYOK_iaJ6ifnPB9m70nbGRs3B-6tk9IvJz-F4bqhXxfS_dH6GDPHLxrCNKnDn1AiE7vAV4tDlremldhdXtHTS20iZxQ_NaG_CiiWTDgR_CvbCcGTI6mvX993hyJ5UyQB3U1HrxmGtIwc7SSNaU3aylEpQ7ofxJxt6K0ko0zkYootood0N1NSFtUIuHTZOhsPvriEaiTZhFL90K_NVspqY9mA-9aT4yB0NWh2orLQUQoJCeXUu4mbzvPQg7Z8faai4j3o8dB2o9z9Vtg2dg6E91OyOKtfj9pg6Bc-mSnW707cbaK8yTEZ-qYbChF5j5SYtoaq_wnBsR3fjUgaOxaxuTE9oZPjifnubEbH-cXYTFImmjJbwRIXLBOmtkTaitTEU8oKwmVv9KCqX_R0DZTPczG8ZnxSfecl5NuWdW-2If_LbNELjv_k4NBq9-AFkdd2dm76HDSL9cWVIhADztkAYSU9NaRCGkYWbQ6FEEBAJo7ZWmDs1ZFNI6JpEhvp0iH1o5EK8i7qsJeALtKStBBSO7c5vOBS7hAaph6f25WVOESmi-ziAOGb0iaZGinNXoer1ZPLbWl6XMg5DowTdyzh2UZX0cC4OuzibIajRlxfrCLOxttZj8e0wYqB94PPc22NzV_NPZkMfvzgVzHJyKH2gYPbNelhK2EnJWmiN9ay2du64uADiPV2RiehroeUy5_9MLJbNtLlWvibmJiRuaG8800pln43q-nEg1As61SbZ8nxfgvs24UfUQG1485gs6YYBLznuzOMWxC2lav1jiA01drIolEydtw-cvURYFiSI_xVt-tyVCPJpBVG_fDTqgq6lygJFvTtJ1as_8LmumRfrdkFS-LdZ-vCadziAhuEvVmagI2_o6BIrtsPl_EndTmdlvTkC2cBy2RIamwEXgn0zxi9f55ogdMlAmMDiS9hTFAj7DPxy-yK6pUWgPgBajNmDRX49PQNnkgA2-fw4LIH8NN9MQxkxGs7EBujIVw8BMmuPYJxsK7PPYVMhmXtDKkmHV40a2XqFTPPK_tr9r748gj5aiJ6vG_t78bJDG4CWrLHDWGovsEmbRsfmXW92v-Nda6adiXaLS02kglfE88a6opJwUrJRJeY0nq98xGuLTAGhY_nleBYNrZZzloJT-Ypkk8qZ4xUTaRrCtnjhc62l-gDQbJBGPEIZsGadKCJJMoPNoUK7naN4jZJO3CjKH8Nh24tozH8zEqu3YkXsSn5SgXya7drm_fg9Aag5W9R29L3xQuZY9crBu5CcKy_3be8KUdKcnmEM656G77TmU8MHJL7nLAvdltANNxAEQMlJ0MR67ClqvS3gbFXQm6dgRaEeTQIE9D2RoYk0NsKImJp8oaXaeWe_b45P8iUVDmF2doQex9zn8IwpaFvSBXWjjVjI7K5YRITyjplbJNBe8Ub-IXZS9v0lGsLkPF9nRrAhICZwJdwaqFdPHrHQzN2uyGTP4jNxVFYO7paUEZODbXG_8gqgIKviaaTmC1s5IHS3yXPGEKgxsFqr5MAlEtBXhLsIEZGwaHAGfuBlulFZECflW6Cp_1_J0b_ihEWKhNjAlAATcQOcS_-VkR7GOlL2I0oIvTrC8DUoTyc5OOY2EBTObY4lnBGiAOQbtxgUzw9NckTyBpdclIvASW_ESafw_luoe3aorAeRQN-o-gHOQ7HZFD2chX4sqEWii7kwSClF79gyhM9x5DsIKDfeA-yhDACUm_ubt3Kut0bu5HBj7wsGpx7cGG408VIK-D2fcUefxnWNbJ-XBeLF8OGXhQRNuGDkj6KKd6Go7AGff4TA4PQDsJIscaC76XbS_pFNKQV-0zcxoAkv_AVwW5oKMbGaQv6x5ugUxIKCOyWqB8QkkqKsYlxZanXbTGuKiXa_IPlZLLI02B6BrUNbU5H-iREMjjucU56go3R5fkSJW4ysYhL_SGGEnh-SQoPxOFEnsfvC4M6Ml6c4M_X14oWNv6A88VMGTqNmAkkWiyRKc7JECUc3DonP6v_izrIo5Bkm81NqwWHBrqRnDVJhHi4usG4Z8b_drQbVK-yllTDHD9_6AHZCVeiupp2J83piyF1R1z58PSIppgJ_60opGGMIrCQIvDlWvP_D_MOe3qlGdGvdYhViRJReK5R2x7qo-nrVG2uJhPtmXdd71sXJAQEAo-VmBkSuB31JKSIHMm3pfInmPKrc4IjioTudNoTtDyvcDTBNu85ogwh5XQsLTJXjWXr9nMLiVKOZjoMIPIgT1vFoSPIndiJGyKtAV3dEYpk2vgbXUa8-oCZPTb7PTfZ39GgO3eoCTJgo-qggY475rCq4nqx_AOAzd3d_34q765kUGXa7-Zsoe6Z5_PHIFpIN-r1BdFbveH8EJ1fhKhOCZqGFGUxxvFVM_0_iLinHZLtGuGhzYMwUwWgFgYoVzo_J5KDOp3ECoCyEina2kYEL_VGn8iHdCAX__jZlwk61zmxou3v4wmPxa4PjXfCRTkYtB6IxDOX7k6j_39JzOz1UQZeE8mrx3Vttc4gK424iYoynd3aJDBXsYHoIkuA2oJUP4jDZtBEDoGiUtKbIkxlbOhY5MypedSBHR1G50ve_4N3V9B8hFIvDrHChl6FE-F_Xpnhtizi27nMKG6urF2R7NfzwtL5ZVYV6G-ytAFOiYMhnaGOTeuAYg3AzAcUkToju4Ldb4syFano2uLSPiVX89gRqPbD7BYw-sKjI8viqlmBT4sRgm5tHu4-NLbOzA1un2RyXlT_4fpbORzCVywhsdlQi_V0H4JR-lUfpkq-etclmMxemxwBRYpebrMTFvPnK0EypiSNMkJRsrAr-kKTeH8C8SMqD3GtnYktYwBnRgFpN38-kzgJfTxzhtqlirlI1PuXXsGQIwofE-AAmHrrrLJWRJYGJsRJd39ACrVRp2hjJDmr1QkHlO62FAKlbOcMokmrMZs7i-D6p4O3UMgEwJAV8iq8r5N2FS8kzNnufuHq1k0Yuj_-NxiRjno8kjNG5KWO9xyTM-mIHLAZwqhcG4Ceu0MibNpNoOgRR5DH0Xesu49fOCiVr-YPGqDKk8Wv_s4AkyA-X60eFv3y3m9Hra5KT0maPrP__LfMXZEidELBJAdW1M3gS_wXNeMowoVTwnK2YL5j1j3u4g8lVMJBSkXe6kLn3nM0qloIoaXxGtRH6qNoglPnZJ6SxAm8qzhVCgHLX_gT9Tqy3HfQ_vNIorEt6tqh8_fYeyc8jyDykQ7oUbCRkl019PRJ9kiLef97vL6hnuEUApJ0x5Fn85ej7rI-i45UcDCchGk_UxV_wJyZ4bqg9TuowsUcF8qtCgqAPL2O_Y9d-ZUttz8EousHkOSF-ZzoywWpiNeuYeIbgA0CsFvXHjfzys5C0fnhJWw-giQ8qiGNiOTVzlXWdp3vSVF_afb--wpLZJV30cazjZtsYh6rVOIWVYeB-JCEM4PRWskMYSqO_We1Da8D3qRHwaFwxAxIbIgNR48uENnTavi6Z0LSaa-nk5vD_UNgxpU4IDRwFdFit9TWWxyz1vbcU-aou3pFPQysawva8pcI2bGysFcnNzJ_f3tZ8ObwcOl_TYxTBq9LBPfN92Uoae3PJ8vly3jDdVseiWOweipoiHTnRqPY1MXexo2xOZZtKgCIre8d8nHxb6OFiTgZ1u9vH2h-I8a9LLrxW_-QQaMN13jZFiFnEu7Vl_Yuxjv6h1nuw37-EM6YyK0783B_QJo-RWFYviyj_m1sngR2r4gp7AZJ5M8BaK-fuxaDtm7SJ45RqxAbNARuXRWJdaJh8gWtSQjwbKBgl_q7eVJWmLPLyeMQd--ktPLb4f6Q_1HYQrx-P91RqE_F25M6HUIe6iC59f8vRlBQq3lQbc1M1ndZsiZfvVmKRdsmXABo91uKnkRAqoCvSq6K7BorH4k20Qpa8xcyNNhA-RSWAFsmx1DMXNyaRKlBxXFkbIDaFz7by0X8G5pVr0whedUuKDGn9GjmhVs5Sxdl1KFtcgwJBteeSVDyu69DBbcp2ArPWexSk7CdbSS4o7ryb9YydF6n__EJxf5uG_dNMct9HhwhRzSZqrui0szrMuZYYWZwrY74j0zXEygu3odLIkXvxa7UIGHt4mq9f3QczSuPEOTo3h0xnpq6tFn9QpEeS479gp1youEtQ1KUNxnME6JCVMzkJ8DyuXWKhYY8h3jX0CoYwb1lfTmLrT8GotlcdZ8g0Pv0COhlZQlOb2GPed3lEZHxRPFq-T-O7iJSKuATmwdeAWLfQP5pbnhVq701sR1kNS2MNOmisqSNBobLqyC7wO1qLGjps5AQlIORxCfbx9HShQWdQMEfLFXnAQ8KcwmoPJgm8ceHg0lxVoFjP91dmsWADHTe4FoEwfl_jR3CLAbT5wHV56iEyqVtZoIdGSCHro0BHQWD0xrjRsa8u2wvj30sHV80ZYAc0uEMkeb10Gvje3m2wHq8-rfTDO1rIx3bvxyw_dwM_IUHBBIfcZNtA8SHdIj5QH5jF6co7_XdDq8gR2zC6OZT5shMfS7PJhBihq8a67eU2mFD5GnS5JDR9o3EVCa1am_ES58fv_Tj8d767wWZQx4GWONPrh7xprHmUly9VMP-HPSrYYS_J3Z0vb1FnaQY7bUY5jIU1H646uzlgpHoHPuoZt47V-i84baU5rL3Eo668rFDeheD3lVeakGyTw9wlwUs7iYncGJM-6-FKbZZJDk_ml1gkYNv75_xkfmDIr-PVnl4XsmVLLOvkF_464ZwsdsA7q5QIOr_yQY2qtvLLA8xWyaINMp2PZfOoWnIjqF-T5KB5hjPQiWRph1e42hqkOjIcXAul-9PuKi8WmRLjl_BB-vF8rxFAWXkt0PHHHo2QGYlKQ3EAPjiei0qzG41WRYQlahdUoXjaKpYElE8vWkHn8LR14DpgptmarZkmR5kQHF951xj_EAINChqgnQp4OPRgXHna4wwxPdD1K3NZqeNvAdzRN0-0z8qMLRwAEe3kgiPsTt8Fv88hZ-D-rRGoXcMoNaFwlY1N8316chIauGYLljBkLa0P6wKQXSN_BaUnVGtVRDESaoHk0XITiR3fE1feCfVKS031CtvH6z9KOY_4MWGJC0R_xwkQzYDM9xXSrhhj68_daEd8ZtY0NYMdfCccxLRr179wxOyN1f56pKSlYq37GHx389470y8UucQIPPU5CbrT710KVHXVtLxfmG-Ft4eF_OwHJx1FY1SP8dwboCZh3DpfoPBihqLgr3VmRZeR_VBkXn_4sj3dZTq-DR754np7SMi_2lzhd-Ynt-GLO8QQGALPSORVngRxi_HHmNNxADnkHmVxTiYHF3vQE9oBJ_DD4ivG8T68rqc7ORqGA196K_zLUpcCP9jigIKWs8jvDdMKULeNDptgIvqIxEA6oXb3apln2q1t-Zx02fNx4QZyxnCbhfGdQ1_UgMCgwEamTLTNbWP5xw18TPLFHFPpCPM1Q7Ng4QeFCe09Av5cQfzgnpWluVoEh86h9QhMy0ze_ap7U-MUKM8-HNaPk7DjUUw1_xv9rmoY86IbADw7MhoTLNdwwdK_VNdxKDUl9RKgXIh61rOWasxAhqIuNIIYRYbOknw2c2zOGKj2bcNiYVOBoAmltgv9txWTXxZ06y-kxWVjIU4oFDjWKvp6Ag6-897KycRKrfU3wgyXqYjNC3crGmrQALaw6PdStq2oH3_zhYCV6wuj_WLQRGGl0ABH12kiGpn9eOEpgGIwkkMnzw70Mf1jHRzXwNsBQWtWq49iYZV4EozvkbCo0cQWa9gVtxMyDXnYwVOpQ-UXOT1akqITJvFWuHMAriABcQ-Cz6pfTQVeTP7zWYxzHZALDp7I95buXsooxU9k0Cxlkj7OdYVYPVeU_vpaedZcklMBzNLijg8umTw7s-riTd5O9fjWh5EyoacecPhaF36jB21kbfWej1SV-6jEgm3py2nA453ZKOrvdQpL28TaRRN6Ga9lSrSIhrCLNV24ducmO7NW-jzTXJBvDVFYKH7jf3QZKLNyNoyE9YHOt562jcBepkfkGEPSe61J7kZEWYFMoudKe3exek_1x2FNpWwn6N5mAFn8SAwqteUo3gXSTrSBhe1tw_RWldLb9fOqOoFX0OtDgDAbl6NZBV8XqM3IGmQoh1XUXrciqw87u6NMdhyishZynBe6gPn3P09RwD7QJqSQaB6ZHnKk1Q_md-y-rbjtRnmCyz7liguD1JabP-0gOz2nXGD85OicRTwZN86wiaetdSWb6e-7L2AQMkumwwQIrS-X9FEuz7B5PvWCn9GdCvhHQT-shH79JxB_3KNggF5Nl1qdVFW4HsyXzeC_lCweHw7Zdb1C5OLOCDu4KahAodENGm0cl7WT24fuOR9YHCTFQwcF8LhhMih_4K_XVojPocVoE9J1MCmmNOLCJFtDK_3OaV5EZz0CZHtoBCXp17f9dIhuRJBD_bR0J67VIj4H4LruLEEpm-PgfOQ2VOy00A2ekTg8wbOQ_pemVVx9AVxmIRjLQ9PDXJ76rJDcagAnJdUHe-BZ8ztu6j0MuP7eIHyU5kz3mbT8K-vYEbmCD006rSPESWIfBK8YpHVFGlftdFXYSk8Uxq9Eu74Xun-rCKUrCDROrdnCAgXQ-IgOrzBwpVGz-UYiS2kp-I_jx_KPD27sfPtqHtLA3W8wAoM-DPt_RJDych2cQmB7At6EZH5wFBftb-q9ufK6_GEIneR-izDMaHnJV8GR4Gmhg3uqBzAL4prhI1jmFggrSmt-8iRASbvR3ouwBF0tT0oX7ZkmY-vqVr_McQ5XcQuVvM7nzMg3zx3P7YzrRa2AfZbIpE6YaLfE4yX3rLYDFwDyJA0KvS-DvIGX9XUfpBkJYxGaKtKYmzn7loHNxHFMbGsA1_uN-MgTN-3TmFx8dAfLfj3vHUi2s_05oItwaoi0098gvuOgCNvILj4zgyCuZWW9S_M6XlijrLCZkmnpaMIOiVBeD-HO-XkfYU0u__wvw6Z6s1dBPh--DbhBfLHM3nRuKJoaYHBEF2k9qi-MzlK8MmfZ0l--9Fiml9hMW0Pr331d0tXM6wdPEONRUA90sN-l-fk5IQzwg0tTuoYInUnJAPDmtE0QT07XPVPibngdBtr0HXGJzDz6heY0QtC3apwrjq7dDt2ZiFo9wqYdbEZ0zRRoe1u3I8OtJxLQyxIrnr-M8cle2Ezcd-Vw71WpQkYz8I1poYbEGad1SobP-2VCG6IzW01IFnfkxc27wqyu_nXFVJlEYv6XYFTE1pXJNyLEqNSzQOzRkvRhh_brwcbWcwcCsU7ycJ0I2hpCE3oeKNdPnYVUOXYZQbbVhaXedeHlOCyDgHVopC6BrEaYnCbVE8zW_fkJFFus0GbUpBnjAF1MNSB7nZie74LX6boLjjhTKYZHNJAED9U79gWbohY528ypjcel9fwrLkCJ0mNMfa4WvMyezQafLOzSMpfZoE5LliRN0enYIzX8zqjgaOkMomdbS84FjehWOR62NpabtggJPbQIaRtAqG9_8WXFZNy0JR1Sx3QW4zvL7RL6hSaMdRUPOCGJwLon2Tkdh2QdZcdXDgEF8g35hToncrEOnkGZVFNu309SoQWqbgYrpb_etPVLLk2nAyN0iVgJJKkcjUt0swDm1Wpm8a5tWz04qO8wX9Xs2vurXxhr36Sfj-ZbvGKAzQg_THoYYd3nC25Q6w6La3GxdN9C2G22D-lp8j8II-EZ2iIZbGxEvg-Qr0NOW76nB9zLpDW5GbUoA2UHGi_CAce5O2fpfSRkqHn7YBLojJA7oRspaWwSbx-gGJd10_nKMGu8lp3TOzarDbLtQYqOsrPl9sbKl9g3-kv9bFCcl8WLWx3HsYxAO1p4dfanqYJ7raYfhq0IOw4On_Rq9iDHXaWv7sQLMO5R6NG2QH3_qdG_AR9pkQtgz6QvHVhyCytJXEN3rk6kjhNepn2FqnelUVzzfgLVp_c-6UbZ8Fdrnt6RsopV9a-CqRreoN1Sv2-QowuiS7GEi0E972dQDzyvWm9gGwYiNCH2uIxzIa32FejkhLO9nN_w_4bqG6WZiMbD_BiTbPWdrQ1dQGXsDvn74FMLpKpOIi7TTkfkO0bj_V8M6acSSEmpd9khKJ_tgL1l31LmQ2b9Db-1Gl4PVRVIoLsPgrenaKcE_9G30qRKJ-7Rg52P5R1HchhY7MMJCGoMM2Elg4brrFtT-LQjcvjkcQqpDHyNtNAOjFd9BjjRqaOEdtpmJNIwxOuwTTNe9TQy07LHQnVMBfeWhMFzpDh_RnzIuqWpCugvlk6n6eo2ii7Wm4I3tSWcANc6LqmMlndayey9p_wgIDU-Y3FTx6ePNquMd0DWJyHViQXSBQFMfjjY_oxt_066-30ZO0x7fFusUXR9RJr4COWjPGgSfjuQvAOvQhiHf7L_CpvAGm7jQYcRvKxXS_pFcUlRIy-cy4wEIGD2GyMFGGMwoBSnHQ6k3dbFbcmE9D6V2pCxLcypbXKoWF0mqAn2Yi3xdcFobULcbfIPxrc8MYPmlDXDzFwCl40iFKOq4IWoSdcn9n2iq5ca_pY5BF3_-kItXY-lpL3ct1zpsCFWa0OQStPtLitwEBC_Ez-13o9120wBobSJDQzy4SxO1XthfQOiUjScihQQv0ovJS81LM6cKvwWqx_zXD6ADGufF2WAKOxr19Sy8ETbkAU8NZwbMvNFPfGAiVDbgJSiNSJV8_bv7MBe4ZvTl5yeOuvLXbGKbHxwx-gpIEUVk6z5BbOCuYpeuq7vGpf9X04Th93VFBqcFVm1O-jWmxSigGzMs_R1-K8CexIirDIqAFoz9abhO7iRPujQrbE7s1jB5FrZjvH2fqSVvfKfZg9a1ZRLvsbWNNK6cMUAP4i3TbeMKtzzy9TGsiQuNUuJhYq27F-T1Z3g2JXJ4ctNRnFuHwCYqX1guPt6Htb05gVcH5IIS-yr6IoYl-qLZN9xJAobOTNiVTh7xFq9UO9ud7ySHenWjPAvEhe7EmL1bvNiWq-eU_2xwwzICzWnzO0Fz7lQSKY8sEB2nMI13rkJmIXyyHn_1RH5IVd8eu-FXNE-O2KQDoas2j5rs2HlP9PU-77vdL-TuG82SdPJt6KA4f9cagZ69yQ3hkgGgpWVOx8s5Y4ju7eCE5r7OgmwCITx5LQEOeUvCt7F38A2Y3B1MAGEkBYxw5RL8XiqoyyCyaErDOaI3OLu3k1f6m-FGkTMOjta3dn7Grx9Slcggy96v9OHuA4nKuLNtwGiAwwE1Extk2_fucYmV7L3MnJrygTplAVsgrvaqF5-veqgQ8_JlAnBY2lEeH_0qiFK0v1yCFl3qUHlMVyLmiZiPu1rE2K_1aD69k99qnTjASSfgzCRXlw11eAT6p5OzBnWPTN_SowwUTEbibXOm0Vyzb6M15kurbXhYHyqJmLMdPVjwngPtebP2kAmcbygm012ojONEsZKuUoRsDMkdG0ELDz0rGeTLWneYFroQvPFR4n2CqxYk0diHYbFdAVcGCpgEoOcQxPlOvusX936CSxDM3ES1V8u2-mA2kDGMyqwA8S12vwAczInCgvK0-cqmnDXkwd39esH2mIS6yq4TPsxmp-IpUPgjzw8b1D8t8rNlBLrYZstfiI-2Jcp-kErqIzi13-CH3cijVpiomqFdj6Xle0d5TmkdE_KwjkRjLjCD7YqpIv_LVnSTDUhQkY3QVWQVfEaWBKux_X7JNW8HH2-sME2MKLYV0P1eDMORgwnpO1nzXXBHUCyMwHH5YzdSShjsQ4EqkHZjGH8qpfGWRYnaQwdnNjDS-qBR7yYrhztUiSfmCCfwzET1XoX5yyI07WlCeSDRVabloU1m1CcO5WEMGIlqttDmHCIj3_sa0L7SybUD-4xlgw_gTvlCSkVPCr4emdhiYBtE9loqjcGgq-fJpmohKl-RvG2nXeW_Lz3rcwHUB_GKFdHe034QyE4hATyCi_T-eifSXfszYes4E2Lqgac6mrusOtakTg2rBIg1YGZUVq5b25E23RPtf2YalWgeh_KZ5MHeZDijgLmqmKs10byDg035DlYFLP0mrjm9DytwVNSgP831xGwH8oI8WRCngXUfdZMz6-JlarnG-GAuNRrrIiQBxRnbDAi15Ca7Vj5EZU5_N8NDj9sLe3xImcNGcVytU5EDGb8E9KP7KPr9n-7t5c2Gzu5sP6cptvlTHiDSG8-o4Tgpryy0WSEHpX26C8hU5ZXJ-NsXybYpqD1XC3_aSlee-HT044D3mZu3GWEBMn6A-Zykwf4-Db-NDifjNFIACOSLiaJ2F99wywymerFG9Sv4edl4utnlNPSqHrq8AxwoOgs4RM7viHLem2EoUnJAcXVplxzgQe9JQ1XeVYc-F9r45NnATug9nWzoKpvUjVkSAIOjlWXPRUezgNLGj0ZoiW0b9iPC1_hprsszHT5IUYwWjeXUt3X5Muamt9ZCTo6eqcysAtMKRIi2ZXFHXQEV56WhPyZiXCP0ORQQQEkfkbQpOHoR7xdACXZQ5tSY7zr1iNDnnU47bgPaAwkxej6SqStKPMfPFd2xvFDnG0JAo3U52BKZvr38nEyMUtckjk6JhH8-rlevnkWmgwSeL4zE1vCoPrZkI1xh_MDZRg.bat3pN99JyHnTD2oK4ntwA"
        }
        """
    
}
