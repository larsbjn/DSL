package dk.sdu.mmmi.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import dk.sdu.mmmi.typescriptdsl.Table
import dk.sdu.mmmi.typescriptdsl.Query

class TypeGenerator implements FileGenerator {
	
	override generate(Resource resource, IFileSystemAccess2 fsa) {
		val tables = resource.allContents.filter(Table).toList
		val queries = resource.allContents.filter(Query).toList
		val generators = newArrayList(new UtilityTypeGenerator, new TableTypeGenerator, new DelegateGenerator, new TableDataGenerator, new ConstraintGenerator)
		val queryGenerator = newArrayList(new QueryGenerator)
		val generatedTables = generators.map[generate(tables)].join('\n')
		val generatedQueries = queryGenerator.map[generate(queries)].join('\n')
		val result = generatedTables.concat(generatedQueries)
		
		fsa.generateFile('index.ts', result)
	}
}