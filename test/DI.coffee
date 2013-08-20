should = require 'should'
path = require 'path'

DI = require '../lib/DI'
Service = require '../lib/Service'
Application = require './data/Application'
Http = require './data/Http'

di = new DI
dir = path.resolve(__dirname + '/data')

describe 'DI', ->

	afterEach( ->
		di.services = {}
	)

	describe '#addService()', ->

		it 'should return instance of new Service class from object', ->
			di.addService('array', Array).should.be.instanceOf(Service)

		it 'should return instance of new Service class from path', ->
			di.addService('app', "#{dir}/Application").should.be.instanceOf(Service)

		it 'should throw an error if you try to register service with reserved name', ->
			( -> di.addService('di', DI) ).should.throw()

	describe '#autowireArguments()', ->

		it 'should return array with services for Application', ->
			di.addService('array', Array)
			di.autowireArguments(Application).should.be.eql([[]])

		it 'should return array with services for inject method', ->
			di.addService('http', Http)
			args = di.autowireArguments((new Application([])).injectHttp)
			args.should.have.length(1)
			args[0].should.be.an.instanceOf(Http)

		it 'should return array with services for Application with custom ones', ->
			di.addService('info', ['hello']).setInstantiate(false)
			app = new Application([])
			di.autowireArguments(app.prepare, ['simq'])

		it 'should throw an error if service to autowire does not exists', ->
			( -> di.autowireArguments(Application) ).should.throw()

		it 'should return array with services from params if they are not in definition', ->
			app = new Application([])
			di.autowireArguments(app.withoutDefinition, ['hello']).should.be.eql(['hello'])

	describe '#createInstance()', ->

		beforeEach( ->
			di.addService('array', Array)
			di.addService('http', Http)
		)

		it 'should return new instance of Application with all dependencies', ->
			app = di.createInstance(Application)
			app.should.be.an.instanceOf(Application)
			app.array.should.be.an.instanceOf(Array)
			app.http.should.be.an.instanceOf(Http)

		it 'should throw an error when service to inject does not exists', ->
			delete di.services.http
			( -> di.createInstance(Application) ).should.throw()

	describe '#findDefinitionByName()', ->

		it 'should return definition of Array service', ->
			di.addService('array', Array)
			di.findDefinitionByName('array').should.be.an.instanceOf(Service)

		it 'should throw an error if service is not registered', ->
			( -> di.findDefinitionByName('array') ).should.throw()

	describe 'Loaders', ->

		beforeEach( ->
			di.addService('array', Array)
			di.addService('http', Http)
			di.addService('info', ['hello'])
				.setInstantiate(false)
			di.addService('noArray', ['not this one'])
				.setInstantiate(false)
				.setAutowired(false)
			di.addService('application', Application)
				.addSetup('prepare', ['simq', '...'])
		)

		describe '#getByName()', ->

			it 'should return instance of Application with all dependencies', ->
				app = di.getByName('application')
				app.should.be.an.instanceOf(Application)
				app.namespace.should.be.equal('simq')
				app.array.should.be.eql([])
				app.http.should.be.an.instanceOf(Http)

			it 'should return always the same instance of Application', ->
				di.getByName('application').should.be.equal(di.getByName('application'))

			it 'should return info array without instantiating it', ->
				di.getByName('info').should.be.eql(['hello'])

			it 'should not set services which are not autowired', ->
				di.findDefinitionByName('application')
					.addSetup('setData')
				( -> di.getByName('application') ).should.throw()

			it 'should autowire di container into Application instance', ->
				di.findDefinitionByName('application')
					.addSetup('setDi')
				di.getByName('application').di.should.be.equal(di)

			it 'should autowire di container factory into Application instance', ->
				di.findDefinitionByName('application')
					.addSetup('setDiFactory')
				factory = di.getByName('application').diFactory
				factory.should.be.an.instanceOf(Function)
				factory().should.be.equal(di)

		describe '#create()', ->

			it 'should return always new instance of Application', ->
				di.create('application').should.not.be.equal(di.create('application'))

		describe '#getFactory()', ->

			it 'should return callable factory for Application', ->
				factory = di.getFactory('application')
				factory.should.be.an.instanceOf(Function)
				factory().should.be.an.instanceOf(Application)