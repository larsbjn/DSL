package dk.sdu.mmmi.generator

import dk.sdu.mmmi.typescriptdsl.Table
import java.util.List

import static extension dk.sdu.mmmi.generator.Helpers.toCamelCase

class DelegateGenerator implements IntermediateGenerator {
	
	override generate(List<Table> tables) '''
		type ClientPromise<T, Args, Payload> = CheckSelect<Args, Promise<T | null>, Promise<Payload | null>>

		«FOR t: tables SEPARATOR '\n'»
		«t.generateDelegate»
		«ENDFOR»
		
		«generateTableClient(tables)»
		«generateQueriesInterface()»
		«generateQueries()»
		«generateClient()»
	'''
	
	private def generateDelegate(Table table) '''
		interface «table.name»Delegate {
			findFirst<T extends «table.name»Args>(args: SelectSubset<T, «table.name»Args>): ClientPromise<«table.name», T, «table.name»GetPayload<T>>
			delete(where: WhereInput<«table.name»>): Promise<number>
			create(data: «table.name»CreateInput): Promise<«table.name»>
			update(args: { where: WhereInput<«table.name»>, data: Partial<«table.name»CreateInput> }): Promise<«table.name»>
		}
	'''
	
	private def generateTableClient(List<Table> tables) '''
		export interface TableClient {
			«FOR t: tables»
			«t.name.toCamelCase»: «t.name»Delegate
			«ENDFOR»
		}	
	'''
	
	private def generateQueriesInterface() '''
		export interface Queries {
			test(x: number): Promise<{ 'firstname': string, 'lastname': string }>
			selectUser(x: number): Promise<User>
		}
	'''
	
	private def generateQueries() '''
		import knex from "knex";
		import {getConfig} from "src/client/config";

		const config = getConfig()
		const knexClient = knex(config)

		export const queries: Record<keyof Queries, any> = {
			test: function (x: number) {
				return knexClient('user').select('firstName')
					.select('lastName').where('age', x).first()
			},
			selectUser: function (x: number) {
				return knexClient('user').first('*').where('age', x)
			}
		}	
	'''	

	
	private def generateClient() '''
		export interface Client extends TableClient, Queries {
			
		}	
	'''
	
}