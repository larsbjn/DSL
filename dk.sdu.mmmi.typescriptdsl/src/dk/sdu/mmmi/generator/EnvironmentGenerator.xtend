package dk.sdu.mmmi.generator

import dk.sdu.mmmi.typescriptdsl.Config
import dk.sdu.mmmi.typescriptdsl.ConfigPassword
import dk.sdu.mmmi.typescriptdsl.ConfigPort
import dk.sdu.mmmi.typescriptdsl.ConfigUrl
import dk.sdu.mmmi.typescriptdsl.ConfigUsername
import dk.sdu.mmmi.typescriptdsl.Database
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import dk.sdu.mmmi.typescriptdsl.ConfigFilePath

class EnvironmentGenerator implements FileGenerator {
	
	override generate(Resource resource, IFileSystemAccess2 fsa) {
		val database = resource.allContents.filter(Database).head
		fsa.generateFile(".env", ''' 
			DATABASE_NAME=«database.name»
			«database.config.map[it.generateConfigurations].join("\n")»
		''')
	}
	
	def CharSequence generateConfigurations(Config config) {
		switch config {
			ConfigUrl: '''DATABASE_HOST=«config.value»'''
			ConfigPort: '''DATABASE_PORT=«config.value»'''
			ConfigUsername: '''DATABASE_USER=«config.value»'''
			ConfigPassword: '''DATABASE_PASSWORD=«config.value»'''
			ConfigFilePath: '''FILEPATH=«config.value»'''
			default: "unknown"
		}
	}
}