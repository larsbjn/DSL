package dk.sdu.mmmi.generator

import java.util.List
import dk.sdu.mmmi.typescriptdsl.Query
import dk.sdu.mmmi.typescriptdsl.QueryType
import static extension dk.sdu.mmmi.generator.Helpers.toCamelCase
import dk.sdu.mmmi.typescriptdsl.Select
import dk.sdu.mmmi.typescriptdsl.AttributeType
import dk.sdu.mmmi.typescriptdsl.IntType
import dk.sdu.mmmi.typescriptdsl.StringType
import dk.sdu.mmmi.typescriptdsl.DateType
import dk.sdu.mmmi.typescriptdsl.Attribute

class QueryGenerator implements IQueryGenerator {
	
	
	override generate(List<Query> queries) '''
		«generateQueriesInterface(queries)»
		«generateQueries(queries)»
		«generateClient()»
	'''
	
	/*private def generateQueriesInterface() '''
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
	'''	*/


	private def generateQueriesInterface(List<Query> queries) '''
		export interface Queries {
			«FOR q: queries.filter[it.queryType instanceof Select]»
				«q.name.toCamelCase»(): Promise<«generateQueryReturnType(q)»>
			«ENDFOR»
		}
	'''	
	
	private def generateQueryReturnType(Query q) {
		/* Få xtext til at fatte ting fra select typen */
		val qt = q.queryType
		switch qt {
			case qt instanceof Select: {
				val temp = qt as Select
				if (temp.all) {
					return q.table.name
				}
				if (!temp.attributes.empty) {
					val str = new StringBuilder("{");
					for (Attribute attr : temp.attributes) {
						val attrString = String.format(" %s: %s,", attr.name, getAttributeTypeAsString(q.table.attributes.findFirst[it.name == attr.name].type))
						str.append(attrString)
					}
					str.append(' }')
					return str.toString
				}
			}
			default: {
				return 'default'
			}
		}
	}

	
	private def generateQueries(List<Query> queries) '''
		import knex from "knex";
		import {getConfig} from "src/client/config";

		const config = getConfig()
		const knexClient = knex(config)

		export const queries: Record<keyof Queries, any> = {
			«FOR q: queries»
				«q.name.toCamelCase»: function() {
					«generateKnexQuery(q)»
				},
			«ENDFOR»
		}	
	'''
	
	private def generateKnexQuery(Query q) {
		val qt = q.queryType
		switch qt {
			case qt instanceof Select: {
				val str = new StringBuilder("return knexClient('" + q.table.name + "')");
				val temp = qt as Select
				if (temp.all) {
					str.append(".select()")
					return str.toString
				}
				if (!temp.attributes.empty) {
					for (Attribute attr : temp.attributes) {
						str.append(".select('" + attr.name + "')")
					}
					return str.toString
				}
			}
		}
	}
	
	private def generateClient() '''
		export interface Client extends TableClient, Queries { }	
	'''
	
	
	private def getAttributeTypeAsString(AttributeType type) {
		switch type {
			IntType: 'number'
			StringType: 'string'
			DateType: 'Date'
			default: 'unknown'
		}
	}
	
	
	
}