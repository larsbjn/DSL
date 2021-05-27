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
import java.util.Set
import dk.sdu.mmmi.typescriptdsl.Or
import dk.sdu.mmmi.typescriptdsl.And
import dk.sdu.mmmi.typescriptdsl.Constraint
import dk.sdu.mmmi.typescriptdsl.CompareConstraint
import dk.sdu.mmmi.typescriptdsl.RegexConstraint
import dk.sdu.mmmi.typescriptdsl.Expression
import dk.sdu.mmmi.typescriptdsl.Plus
import dk.sdu.mmmi.typescriptdsl.Minus
import dk.sdu.mmmi.typescriptdsl.Mult
import dk.sdu.mmmi.typescriptdsl.Div
import dk.sdu.mmmi.typescriptdsl.Parenthesis
import dk.sdu.mmmi.typescriptdsl.Field
import dk.sdu.mmmi.typescriptdsl.NumberExp
import java.util.Map
import java.util.HashMap
import dk.sdu.mmmi.typescriptdsl.Parameter
import java.util.HashSet

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
				«q.name.toCamelCase»(«generateQueryParameters(q)»): Promise<«generateQueryReturnType(q)»>
			«ENDFOR»
		}
	'''	
	
	private def generateQueryParameters(Query q) {
		val where = q.where
		val parameters = where.parameters(new HashMap)
		val str = new StringBuilder("")
		parameters.forEach[name, type|
			str.append(name + ": " + type + ",")
		]
		return str
	}
	
	def Map<String, String> parameters(Constraint cons, Map<String, String> parameters) {
		switch cons {
			CompareConstraint: {
				val type = cons.left.printParametersExp
				val name = cons.right.printParametersExp.toString
				if (!name.empty) {
					parameters.put(name.toString, type.toString)	
				}
			}
			Or: {
				cons.left.parameters(parameters)
				cons.right.parameters(parameters)
			}
			And: {
				cons.left.parameters(parameters)
				cons.right.parameters(parameters)
			}
			default: {
				println("Not found")	
			}
		}
		return parameters
	}
	
	def CharSequence printParametersExp(Expression exp) {
		switch exp {
			Plus: {
				exp.left.printParametersExp
				exp.right.printParametersExp	
			}
			Minus: {
				exp.left.printParametersExp
				exp.right.printParametersExp	
			}
			Mult: {
				exp.left.printParametersExp
				exp.right.printParametersExp	
			}
			Div: {
				exp.left.printParametersExp
				exp.right.printParametersExp	
			}
			NumberExp: {
				''''''
			}
			Field: {
				'''«exp.attr.type.attributeTypeAsString»'''
			}
			Parameter: {
				'''«exp.value»'''
			}
			
			default: throw new Exception()
		}
	}
	
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
				«q.name.toCamelCase»: function(«generateQueryParameters(q)») {
					«generateKnexQuery(q)»«generateWhere(q.where)»
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
	
	private def generateWhere(Constraint c) {
		if (c === null) {
			return ''
		}
		var parameters = c.generateWhereRawParameters.toString
		var str = new StringBuilder('.whereRaw("' + c.constraints)
		if (parameters.empty) {
			str.append('")')
		} else {
			str.append(parameters + ')')
		}
		return str
	}
	
	def CharSequence generateWhereRawParameters(Constraint cons) {
		val parameters = cons.rawParameters(new HashSet<String>)
		if (parameters.empty) {
			return ''
		}
		var str = new StringBuilder('", [')
		for (String s : parameters) {
			println(s)
			str.append(s + ',')
		}
		str.append(']')
		return str
	}
	
	def Set<String> rawParameters(Constraint cons, Set<String> parameters) {
		switch cons {
			CompareConstraint: {
				val left = cons.left.printRawParameters.toString
				val right = cons.right.printRawParameters.toString
				if (!left.empty) {
					parameters.add(left)
				}
				if (!right.empty) {
					parameters.add(right)
				}
			}
			Or: {
				cons.left.rawParameters(parameters)
				cons.right.rawParameters(parameters)	
			}
			And: {
				cons.left.rawParameters(parameters)
				cons.right.rawParameters(parameters)	
			}
			default: {
				println("Unknown")
			}
		}
		return parameters
	}
	
	def CharSequence printRawParameters(Expression exp) {
		switch exp {
			Parameter: '''«exp.value»'''
			default: ''''''
		}
	}
	
	def CharSequence constraints(Constraint cons) {
		switch cons {
			RegexConstraint: ''''''
			CompareConstraint: '''«cons.left.printExp» «cons.operator» «cons.right.printExp»'''
			Or: '''«cons.left.constraints()» or «cons.right.constraints()»'''
			And: '''«cons.left.constraints()» and «cons.right.constraints()»'''
			default: "unknown"
		}
	}
	
	def CharSequence printExp(Expression exp) {
		switch exp {
			Plus: '''«exp.left.printExp» + «exp.right.printExp»'''
			Minus: '''«exp.left.printExp» - «exp.right.printExp»'''
			Mult: '''«exp.left.printExp» * «exp.right.printExp»'''
			Div: '''«exp.left.printExp» / «exp.right.printExp»'''
			Parenthesis: '''(«exp.exp.printExp»)'''
			NumberExp: '''«exp.value»'''
			Field: '''«exp.attr.name»'''
			Parameter: '''?'''
			default: throw new Exception()
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