function identify_role() {
    AUTOSCALENAME="";ELBNAME=""
    case ${ROLEENVNAME} in
        socorroweb-stage )
            AUTOSCALENAME="as-stage-socorroweb"
            ELBNAME="elb-stage-socorroweb"
            TERRAFORMNAME="webapp"
            ;;

        collector-stage )
            AUTOSCALENAME="as-stage-collector"
            ELBNAME="elb-stage-collector"
            TERRAFORMNAME="collector"
            ;;

        processor-stage )
            AUTOSCALENAME="as-stage-processor"
            ELBNAME="NONE"
            TERRAFORMNAME="processor"
            ;;

        socorroanalysis-stage )
            AUTOSCALENAME="as-stage-socorroanalysis"
            ELBNAME="elb-stage-socorroanalysis"
            TERRAFORMNAME="analysis"
            ;;

        socorroadmin-stage )
            AUTOSCALENAME="as-stage-socorroadmin"
            ELBNAME="NONE"
            TERRAFORMNAME="admin"
            ;;

        symbolapi-stage )
            AUTOSCALENAME="as-stage-symbolapi"
            ELBNAME="elb-stage-symbolapi"
            TERRAFORMNAME="symbolapi"
            ;;

        socorroweb-prod )
            AUTOSCALENAME="as-prod-socorroweb"
            ELBNAME="elb-prod-socorroweb"
            TERRAFORMNAME="webapp"
            ;;

        collector-prod )
            AUTOSCALENAME="as-prod-collector"
            ELBNAME="elb-prod-collector"
            TERRAFORMNAME="collector"
            ;;

        processor-prod )
            AUTOSCALENAME="as-prod-processor"
            ELBNAME="NONE"
            TERRAFORMNAME="processor"
            ;;

        socorroanalysis-prod )
            AUTOSCALENAME="as-prod-socorroanalysis"
            ELBNAME="elb-prod-socorroanalysis"
            TERRAFORMNAME="analysis"
            ;;

        socorroadmin-prod )
            AUTOSCALENAME="as-prod-socorroadmin"
            ELBNAME="NONE"
            TERRAFORMNAME="admin"
            ;;

        symbolapi-prod )
            AUTOSCALENAME="as-prod-symbolapi"
            ELBNAME="elb-prod-symbolapi"
            TERRAFORMNAME="symbolapi"
            ;;

        * )
            echo "`date` -- Unable to match appname and env to an existing deployment, check the args passed to deploy.sh"
            exit 1
            ;;
    esac
}
