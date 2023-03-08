#!/usr/bin/env groovy 

/*****************************************************************************
 * Methods
 *****************************************************************************/
stashes = []

def String destinationBranch(env) {
    return (env.CHANGE_TARGET != null) ? env.CHANGE_TARGET : "main"
}

def String sourceBranch(env) {
    return (env.CHANGE_BRANCH != null) ? env.CHANGE_BRANCH : env.GIT_BRANCH
}

def String getGitBranchName(scm, env) {
    echo scm.branches[0].name
    return (env.BRANCH_NAME != null) ? env.BRANCH_NAME : scm.branches[0].name
}

/*****************************************************************************
 * Pipeline
 *****************************************************************************/

pipeline {
    agent none
    stages {
        stage('mingw') {
            environment {
                USER = "${env.USER}"
                BUILD_NUMBER = "${env.BUILD_NUMBER}"
                COMPARE_BRANCH = destinationBranch(env)
                CURRENT_BRANCH = getGitBranchName(scm, env)
                GIT_SSH_COMMAND = 'ssh -i /datadisk/.ssh/id_rsa'
            }//environment
            agent { node { label 'linux' } }
            options { skipDefaultCheckout true }
            steps {
                dir('scm.factory-installer.' + "${env.BUILD_NUMBER}"){
                    checkout scm
                     script {
                        statusCode = sh  script:"""#!/bin/bash
                        printenv
                        git checkout "\${CURRENT_BRANCH}"
                        git submodule update --recursive --init
                        project_path=\$(echo "\$PWD" | sed -r "s|\$JENKINS_HOME|\$HOST_JENKINS_HOME|")
                        ./enter-docker.sh build_number="${env.BUILD_NUMBER}" job_name="${env.JOB_NAME}" project_path="\${project_path} target=mingw" 
                        """, returnStatus:true

                        if (statusCode != 0) {
                            currentBuild.result = 'FAILURE'
                            error "Failed to build"
                        }
                        else {
                            archiveArtifacts artifacts: "mingw-build/*zip", fingerprint: true
                        }
                    }//script
                }//dir
            }//steps
        }//'mingw'
     }//stages
}//pipeline


