const path = require(`path`)
const _ = require("lodash")

const { createFilePath } = require(`gatsby-source-filesystem`)

exports.createPages = async ({ graphql, actions, reporter }) => {
  const { createPage } = actions

  // Create exercises pages
  const exercises = await graphql(
    `
      {
        allMarkdownRemark {
          nodes {
            id
            fields {
              slug
            }
          }
        }
      }
    `
  )

  if (exercises.errors) {
    reporter.panicOnBuild(
      `There was an error loading your blog posts`,
      exercisesResult.errors
    )
    return
  }

  exercises.data.allMarkdownRemark.nodes.forEach((exercise, index) => {
    createPage({
      path: exercise.fields.slug,
      component: path.resolve(`./src/templates/exercise.js`),
      context: {
        id: exercise.id,
      },
    })
  })

  // Create tags pages
  const tags = await graphql(`
    {
      allMarkdownRemark {
        group(field: frontmatter___tags) {
          fieldValue
        }
      }
    }
  `)

  _.each(tags.data.allMarkdownRemark.group, tag => {
    createPage({
      path: `/tag/${tag.fieldValue}`,
      component: path.resolve(`./src/templates/tag-template.js`),
      context: {
        tag: tag.fieldValue,
      },
    })
  })
}

exports.onCreateNode = ({ node, actions, getNode }) => {
  const { createNodeField } = actions

  if (node.internal.type === `MarkdownRemark`) {
    const value = createFilePath({ node, getNode })

    createNodeField({
      name: `slug`,
      node,
      value,
    })

    if (node.frontmatter.tags) {
      const tagSlugs = node.frontmatter.tags.map(tag => `/tag/${tag}`)
      createNodeField({ name: "tagSlugs", node, value: tagSlugs })
    }
  }
}

exports.createSchemaCustomization = ({ actions }) => {
  const { createTypes } = actions
  createTypes(`
    type SiteSiteMetadata {
      author: Author
      siteUrl: String
      social: Social
    }

    type Author {
      name: String
      summary: String
    }

    type Social {
      twitter: String
    }

    type MarkdownRemark implements Node {
      frontmatter: Frontmatter
      fields: Fields
    }

    type Frontmatter {
      title: String
      tags: [String]
    }

    type Fields {
      slug: String
      tagSlugs: [String]
    }
  `)
}
