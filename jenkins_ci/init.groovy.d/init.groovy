import jenkins.model.*
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import hudson.plugins.git.*
import hudson.security.*
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*


def instance = Jenkins.getInstance()

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('admin', 'admin')
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)
instance.save()

// Set up the pipeline job
def jenkins = Jenkins.instance
def jobName = "spring-petclinic-pipeline"

// Check if the job already exists
def job = jenkins.getItem(jobName)
if (job != null) {
    println "Job $jobName already exists. Deleting the existing job."
    job.delete()
}

println "Creating new job: $jobName"

// Create a new pipeline job
def pipelineJob = jenkins.createProject(org.jenkinsci.plugins.workflow.job.WorkflowJob, jobName)

// Define the pipeline script from SCM
def scm = new GitSCM("https://github.com/bintangadinandra/spring-petclinic-devops-group3.git")
scm.branches = [new BranchSpec("*/main")]
def scmDefinition = new CpsScmFlowDefinition(scm, "Jenkinsfile")

pipelineJob.definition = scmDefinition

// Set up triggers
pipelineJob.addTrigger(new hudson.triggers.SCMTrigger("* * * * *"))
pipelineJob.save()

println "Job $jobName created successfully."


def privateKey = new File('/var/jenkins_home/init.groovy.d/ec2.pem').text
def credentials = new BasicSSHUserPrivateKey(
    CredentialsScope.GLOBAL,
    'ec2-key',  // Credential ID
    'ubuntu',         // Username
    new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(privateKey),
    '',                      // Passphrase (if any)
    'SSH Key for Deployment' // Description
)

def domain = Domain.global()
def store = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
store.addCredentials(domain, credentials)