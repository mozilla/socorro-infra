function identify_role() {
    AUTOSCALENAME="";ELBNAME=""
    case ${ROLEENVNAME} in
        socorroweb-stage )
            AUTOSCALENAME="as-stage-socorroweb"
            ELBNAME="elb-stage-socorroweb"
            TERRAFORMNAME="webapp"
            SSLELB="true"
            APPLYSCALINGPOLICY="true"
            NOTIFYFORUNHEALTHYELB="true"
            ;;

        collector-stage )
            AUTOSCALENAME="as-stage-collector"
            ELBNAME="elb-stage-collector"
            TERRAFORMNAME="collector"
            SSLELB="true"
            APPLYSCALINGPOLICY="true"
            NOTIFYFORUNHEALTHYELB="true"
            ;;

        processor-stage )
            AUTOSCALENAME="as-stage-processor"
            ELBNAME="NONE"
            TERRAFORMNAME="processor"
            SSLELB="false"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="false"
            ;;

        socorroanalysis-stage )
            AUTOSCALENAME="as-stage-socorroanalysis"
            ELBNAME="elb-stage-socorroanalysis"
            TERRAFORMNAME="analysis"
            SSLELB="true"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="true"
            ;;

        socorroadmin-stage )
            AUTOSCALENAME="as-stage-socorroadmin"
            ELBNAME="NONE"
            TERRAFORMNAME="admin"
            SSLELB="false"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="false"
            ;;

        symbolapi-stage )
            AUTOSCALENAME="as-stage-symbolapi"
            ELBNAME="elb-stage-symbolapi"
            TERRAFORMNAME="symbolapi"
            SSLELB="true"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="false"
            ;;

        consul-stage )
            AUTOSCALENAME="as-stage-consul"
            ELBNAME="elb-stage-consul"
            TERRAFORMNAME="consul"
            SSLELB="false"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="true"
            ;;

        socorrorabbitmq-stage )
            AUTOSCALENAME="as-stage-socorrorabbitmq"
            ELBNAME="elb-stage-socorrorabbitmq"
            TERRAFORMNAME="rabbitmq"
            SSLELB="false"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="true"
            ;;

        elasticsearch-stage )
            AUTOSCALENAME="as-stage-socorroelasticsearch"
            ELBNAME="elb-stage-socorroelasticsearch"
            TERRAFORMNAME="elasticsearch"
            SSLELB="false"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="true"
            ;;

        socorrobuildbox-stage )
            AUTOSCALENAME="as-stage-socorrobuildbox"
            ELBNAME="elb-stage-socorrobuildbox"
            TERRAFORMNAME="buildbox"
            SSLELB="true"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="true"
            ;;

        socorroweb-prod )
            AUTOSCALENAME="as-prod-socorroweb"
            ELBNAME="elb-prod-socorroweb"
            TERRAFORMNAME="webapp"
            SSLELB="true"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="true"
            ;;

        collector-prod )
            AUTOSCALENAME="as-prod-collector"
            ELBNAME="elb-prod-collector"
            TERRAFORMNAME="collector"
            SSLELB="true"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="true"
            ;;

        processor-prod )
            AUTOSCALENAME="as-prod-processor"
            ELBNAME="NONE"
            TERRAFORMNAME="processor"
            SSLELB="false"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="false"
            ;;

        socorroanalysis-prod )
            AUTOSCALENAME="as-prod-socorroanalysis"
            ELBNAME="elb-prod-socorroanalysis"
            TERRAFORMNAME="analysis"
            SSLELB="true"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="true"
            ;;

        socorroadmin-prod )
            AUTOSCALENAME="as-prod-socorroadmin"
            ELBNAME="NONE"
            TERRAFORMNAME="admin"
            SSLELB="false"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="false"
            ;;

        symbolapi-prod )
            AUTOSCALENAME="as-prod-symbolapi"
            ELBNAME="elb-prod-symbolapi"
            TERRAFORMNAME="symbolapi"
            SSLELB="false"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="true"
            ;;

        consul-prod )
            AUTOSCALENAME="as-prod-consul"
            ELBNAME="elb-prod-consul"
            TERRAFORMNAME="consul"
            SSLELB="false"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="true"
            ;;

        rabbitmq-prod )
            AUTOSCALENAME="as-prod-rabbitmq"
            ELBNAME="elb-prod-rabbitmq"
            TERRAFORMNAME="rabbitmq"
            SSLELB="false"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="true"
            ;;

        elasticsearch-prod )
            AUTOSCALENAME="as-prod-socorroelasticsearch"
            ELBNAME="elb-prod-socorroelasticsearch"
            TERRAFORMNAME="elasticsearch"
            SSLELB="false"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="true"
            ;;

        socorrobuildbox-prod )
            AUTOSCALENAME="as-prod-socorrobuildbox"
            ELBNAME="elb-prod-socorrobuildbox"
            TERRAFORMNAME="buildbox"
            SSLELB="true"
            APPLYSCALINGPOLICY="false"
            NOTIFYFORUNHEALTHYELB="true"
            ;;

        * )
            echo "`date` -- Unable to match appname and env to an existing deployment, check the args passed to deploy.sh"
            exit 1
            ;;
    esac
}
