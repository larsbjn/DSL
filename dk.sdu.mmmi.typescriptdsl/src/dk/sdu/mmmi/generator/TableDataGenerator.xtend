package dk.sdu.mmmi.generator

import dk.sdu.mmmi.typescriptdsl.Table
import java.util.List

import static extension dk.sdu.mmmi.generator.Helpers.*

class TableDataGenerator implements IntermediateGenerator {
	
	override generate(List<Table> tables) {		
		tables.generateTablesTypes
	}
	
	private def generateTablesTypes(List<Table> tables) '''
		export interface TableData {
			typeName: string
			tableName: string
			primaryKey: string
		}
		
		export const tableData: Record<keyof TableClient, TableData> = {
			«FOR t: tables SEPARATOR ','»
			«t.generateTable»
			«ENDFOR»
		}
	'''
	
	private def generateTable(Table table) '''
		«table.name.toCamelCase»: {
			typeName: '«table.name.toCamelCase»',
			tableName: '«table.name.toSnakeCase»',
			primaryKey: '«table.primaryKey.name.toSnakeCase»'
		}
	'''
}